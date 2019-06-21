
  CREATE OR REPLACE PACKAGE "BILL_API"."PROCESS_BOA_FEED"
IS

   program_name VARCHAR2(20) := 'PROCESS_BOA_FEED';
   number_processed NUMBER := 0;

   CURSOR feed_trx_payments_cursor IS
	SELECT DISTINCT
	a.filename, a.fileprocesseddatetime,
	a.filecreationdatetime, a.destinationdda, a.accountnumber,
	a.depositdate, a.totalchecks, a.totaldollarsamount,
	a.batchnumber, a.batchtransactionscount, a.itemnumber,
	a.transactiondollaramount, a.transitroutingnumber,
	a.accountnumberofthecheck, a.checknumberofthecheck,
	a.brokernumber, a.transactiontype
	FROM bill_st.feed_transaction_payments a
	WHERE a.processed <> 1
	AND a.filename in (
'CDA-Test_Dep-Date-5'
	)
	ORDER BY a.filename,a.brokernumber, checknumberofthecheck;

   feed_trx_payments_rec feed_trx_payments_cursor%ROWTYPE;

   PROCEDURE MainLoop;
   PROCEDURE GetSuspenseAccount;
   PROCEDURE ProcessPayment;
   PROCEDURE GetCustomer(p_broker_number IN NUMBER, p_check_number IN VARCHAR, p_filename IN VARCHAR, p_check_amount IN NUMBER);
   PROCEDURE ProcessProducerExternalAcct(p_transaction_type IN VARCHAR, p_feed_row_id IN NUMBER);
   PROCEDURE ProcessReceivable;
   PROCEDURE InsertBillPayment(p_customer_id IN NUMBER, p_payment_type_id IN NUMBER, p_bank_account_id IN NUMBER, p_feed_row_id IN NUMBER);
   PROCEDURE CombinedInvoices(p_combined_invoice_parent IN NUMBER, p_policy_number IN VARCHAR,
	p_transaction_dollar_amount IN VARCHAR, p_invoice_amount IN NUMBER, p_deposit_date IN DATE,
	p_check_number IN VARCHAR, p_broker_number IN NUMBER, p_feed_row_id IN NUMBER);
   PROCEDURE ProcessChildInvoices(p_combined_invoice_parent IN VARCHAR2, p_policy_number IN VARCHAR,
	p_invoice_amount IN NUMBER, p_deposit_date IN DATE, p_check_number IN VARCHAR, p_broker_number IN NUMBER, p_feed_row_id IN NUMBER);
   PROCEDURE GetReceivableByInvoiceNum(p_invoice_number IN VARCHAR2);
   PROCEDURE GetReceivableByPolicyNumber(p_policy_number IN VARCHAR2, p_transaction_amt IN NUMBER);
   PROCEDURE ApplyPayment(p_invoice_amount IN NUMBER, p_deposit_date IN DATE,
	p_check_number IN VARCHAR, p_broker_number IN NUMBER, p_feed_row_id IN NUMBER, p_invoice_number IN VARCHAR);
   PROCEDURE UpdateARCombinedInvoice(p_policy_num IN NUMBER, p_policy_trx_id IN NUMBER, p_policy_trx_type IN VARCHAR2);
   PROCEDURE UpdateFeedTransactionPayments(p_filename IN VARCHAR, p_checknumber IN VARCHAR);
   PROCEDURE UpdateFeedTransactionPayments(p_row_id IN NUMBER);
   PROCEDURE UpdateCustomerBillItem
    (
	in_applied_amount IN NUMBER,
	in_applied_amount_usd IN NUMBER DEFAULT NULL,
	in_bill_item_id IN NUMBER,
	in_user IN VARCHAR2,
	in_feed_row_id IN NUMBER,
	in_payment_id IN NUMBER DEFAULT NULL, -- used for fx on foreign currency
	in_payment_applied_id IN NUMBER DEFAULT NULL -- used for fx on foreign currency
    );
   PROCEDURE UpdateCustomerBill
    (
	in_bill_id IN NUMBER,
	in_bill_status IN VARCHAR2,
	in_user IN VARCHAR2
    );
   FUNCTION InsertIntoPaymentApplied
   (
      in_bill_item_id IN NUMBER,
      in_payment_id IN NUMBER,
      in_applied_amount IN FLOAT,
      in_user IN VARCHAR2,
      in_credit IN VARCHAR2,
      in_credit_reason IN VARCHAR2,
      in_credit_date IN VARCHAR2,
      in_credit_reference_number IN VARCHAR2,
      in_refund IN VARCHAR2,
      in_refund_reason IN VARCHAR2,
      in_refund_date IN VARCHAR2,
      in_reallocated_bill_item_id IN NUMBER,
      in_payment_comment IN VARCHAR2,
      in_currency_id IN NUMBER DEFAULT 1,
      in_fx_amount FLOAT DEFAULT 0,
      in_applied_amount_usd IN FLOAT DEFAULT NULL
    )
    RETURN NUMBER;


END PROCESS_BOA_FEED;
/
CREATE OR REPLACE PACKAGE BODY "BILL_API"."PROCESS_BOA_FEED"
IS
    v_suspense_acct_customer_id NUMBER NULL;
    v_filename VARCHAR(256) NULL;
    v_bill_item_id NUMBER NULL;
    v_balance NUMBER NULL;
    v_net_due_amt NUMBER NULL;
    v_tot_payments_applied_amt NUMBER NULL;
    v_customer_ID NUMBER NULL;
    v_bill_id NUMBER NULL;
    v_invoice_number VARCHAR(30) NULL;
    v_policy_number VARCHAR(30) NULL;
    v_payment_id NUMBER NULL;
    v_valid_broker_payment NUMBER(1) := 0;

    PROCEDURE MainLoop
    IS
    BEGIN
	GetSuspenseAccount;

	OPEN feed_trx_payments_cursor;
	BEGIN

	BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,'', '', 'Start PROCESS_BOA_FEED.', '', SYSDATE);

	END;
	LOOP
	    FETCH feed_trx_payments_cursor INTO feed_trx_payments_rec;
	    EXIT WHEN feed_trx_payments_cursor%NOTFOUND;

	    v_filename := feed_trx_payments_rec.filename;
	    ProcessPayment;
	    IF (v_payment_id IS NOT NULL AND v_valid_broker_payment = 1) THEN
		ProcessReceivable;
	    END IF;

	    COMMIT;

	    number_processed := number_processed + 1;
	END LOOP;

	BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,'', '', 'End PROCESS_BOA_FEED. Number of Checks Processed: '||number_processed, '', SYSDATE);

	CLOSE feed_trx_payments_cursor;


	EXCEPTION
	    WHEN others THEN
		ROLLBACK;
		BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,'', to_char(SQLCODE), SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
		CLOSE feed_trx_payments_cursor;

    END MainLoop;

    PROCEDURE GetSuspenseAccount
    IS

    BEGIN
	SELECT CUSTOMER_ID INTO v_suspense_acct_customer_id FROM customer a
	WHERE a.customer_entity_name = 'BoA Suspense Account' AND a.customer_type = 'Suspense Account';
	--DBMS_OUTPUT.put_line('Suspense acct: '||v_suspense_acct_customer_id);
	EXCEPTION WHEN others THEN
	    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.GetSuspenseAccount selecting suspense acct.', v_filename,
	    to_char(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);

    END GetSuspenseAccount;

    PROCEDURE ProcessPayment
    IS
       v_payment_type_id NUMBER NULL;
       v_bank_account_id NUMBER NULL;
       v_feed_row_id NUMBER NULL;
    BEGIN

	BEGIN
	    SELECT max(id) INTO v_feed_row_id FROM bill_st.feed_transaction_payments a
	    WHERE a.filename = v_filename AND a.checknumberofthecheck = feed_trx_payments_rec.checknumberofthecheck
	    AND a.transactiondollaramount = feed_trx_payments_rec.TRANSACTIONDOLLARAMOUNT
	    AND nvl(a.brokernumber,'') = nvl(feed_trx_payments_rec.BROKERNUMBER,'');
	    EXCEPTION
		WHEN others THEN
		    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.ProcessPayment. Error retrieving row id for broker #:'
			||feed_trx_payments_rec.brokernumber||'.'
			, v_filename, to_char(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
		    InsertBillPayment(NULL,v_payment_type_id,v_bank_account_id, v_feed_row_id);
		    RETURN;
	END;
	--look up payment type id
	IF feed_trx_payments_rec.transactiontype IS NOT NULL THEN
	    BEGIN
		SELECT PAYMENT_TYPE_ID INTO v_payment_type_id FROM payment_type a
		WHERE a.payment_type_desc = CASE WHEN feed_trx_payments_rec.transactiontype = 'CHK' THEN 'Lockbox' ELSE feed_trx_payments_rec.transactiontype END
		AND a.payment_category = 'Incoming';
		EXCEPTION WHEN no_data_found THEN
		    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,feed_trx_payments_rec.filename, v_filename, 'Invalid payment type for broker #: '
		    ||feed_trx_payments_rec.brokernumber||', transaction amt: '
		    ||feed_trx_payments_rec.TRANSACTIONDOLLARAMOUNT
		    ||', check number: '
		    ||feed_trx_payments_rec.checknumberofthecheck
		    ||'. Payment added to suspense.', '', SYSDATE);
	    END;
	ELSE
	    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,feed_trx_payments_rec.filename, v_filename, 'Transaction type is null for broker #: '
		||feed_trx_payments_rec.brokernumber||', transaction amt: '
		||feed_trx_payments_rec.TRANSACTIONDOLLARAMOUNT||', check number: '
		||feed_trx_payments_rec.checknumberofthecheck
		||'. Payment added to suspense.', '', SYSDATE);
	END IF;
	--lookup account
	IF feed_trx_payments_rec.accountnumber IS NOT NULL AND feed_trx_payments_rec.accountnumber != 9999999 THEN
	    BEGIN
		SELECT BANK_ACCT_ID INTO v_bank_account_id FROM bank_account a
		WHERE a.feed_acct_number = to_char(feed_trx_payments_rec.accountnumber);
		EXCEPTION WHEN no_data_found THEN
		    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,feed_trx_payments_rec.filename, v_filename, 'Invalid bank acct # for broker #: '
			||feed_trx_payments_rec.brokernumber||', transaction amt: '
			||feed_trx_payments_rec.TRANSACTIONDOLLARAMOUNT||', check number: '
			||feed_trx_payments_rec.checknumberofthecheck
			||'. Payment added to suspense.', '', SYSDATE);
	    END;
	ELSIF feed_trx_payments_rec.DESTINATIONDDA IS NOT NULL THEN
	    BEGIN
		SELECT BANK_ACCT_ID INTO v_bank_account_id FROM bank_account a
		WHERE a.destination_dda = to_char(feed_trx_payments_rec.DESTINATIONDDA);
		EXCEPTION WHEN no_data_found THEN
		    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,feed_trx_payments_rec.filename, v_filename, 'Invalid destination dda # for broker #: '
			||feed_trx_payments_rec.brokernumber||', transaction amt: '
			||feed_trx_payments_rec.TRANSACTIONDOLLARAMOUNT||', check number: '
			||feed_trx_payments_rec.checknumberofthecheck
			||'. Payment added to suspense.', '', SYSDATE);
	    END;
	ELSE
	    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,feed_trx_payments_rec.filename, v_filename, 'Bank account not found for broker #: '
		||feed_trx_payments_rec.brokernumber||', transaction amt: '
		||feed_trx_payments_rec.TRANSACTIONDOLLARAMOUNT||', check number: '
		||feed_trx_payments_rec.checknumberofthecheck
		||'. Payment added to suspense.', '', SYSDATE);
	END IF;

	IF (feed_trx_payments_rec.brokernumber IS NOT NULL
	    AND v_payment_type_id IS NOT NULL AND v_bank_account_id IS NOT NULL) THEN
	    BEGIN
		GetCustomer(feed_trx_payments_rec.brokernumber, feed_trx_payments_rec.checknumberofthecheck, feed_trx_payments_rec.filename, feed_trx_payments_rec.TRANSACTIONDOLLARAMOUNT);
		--test if gets here if no customer found or goes to exception
		--IF v_customer_id IS NULL THEN
		    ProcessProducerExternalAcct(feed_trx_payments_rec.transactiontype, v_feed_row_id);
		--END IF;
		EXCEPTION
		    WHEN no_data_found THEN
			BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,feed_trx_payments_rec.filename, '', 'Customer not found for broker #: '
			    ||feed_trx_payments_rec.brokernumber
			    ||'. Payment added to suspense.', '', SYSDATE);
			InsertBillPayment(NULL,v_payment_type_id,v_bank_account_id, v_feed_row_id);
			RETURN;
		    WHEN others THEN
			BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.GetCustomer. Error processing payment for broker #:'
			    ||feed_trx_payments_rec.brokernumber||'.'
			    , v_filename, to_char(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
			InsertBillPayment(NULL,v_payment_type_id,v_bank_account_id, v_feed_row_id);
			RETURN;
	    END;
	    --valid payment
	    InsertBillPayment(v_customer_id,v_payment_type_id,v_bank_account_id, v_feed_row_id);
	    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,feed_trx_payments_rec.filename, '', 'Payment added for broker #: '
			||rtrim(feed_trx_payments_rec.brokernumber)||', check #: '||feed_trx_payments_rec.checknumberofthecheck
			||', amount: '||feed_trx_payments_rec.TRANSACTIONDOLLARAMOUNT, '', SYSDATE);
	ELSIF feed_trx_payments_rec.brokernumber IS NULL THEN
	    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,feed_trx_payments_rec.filename, '', 'Broker # is null for transaction amt: '
		    ||feed_trx_payments_rec.TRANSACTIONDOLLARAMOUNT||', check number: '
		    ||feed_trx_payments_rec.checknumberofthecheck
		    ||'. Payment added to suspense.', '', SYSDATE);

	    InsertBillPayment(NULL,v_payment_type_id,v_bank_account_id, v_feed_row_id);
	    UpdateFeedTransactionPayments(feed_trx_payments_rec.filename, feed_trx_payments_rec.checknumberofthecheck);
	    RETURN;
	ELSE
	    InsertBillPayment(NULL,v_payment_type_id,v_bank_account_id, v_feed_row_id);
	    UpdateFeedTransactionPayments(feed_trx_payments_rec.filename, feed_trx_payments_rec.checknumberofthecheck);
	    RETURN;
	END IF;

    END ProcessPayment;

    PROCEDURE GetCustomer(p_broker_number IN NUMBER, p_check_number IN VARCHAR, p_filename IN VARCHAR, p_check_amount IN NUMBER)
    IS
	v_customer_pol_num VARCHAR(50) NULL;
	v_customer_inv_num VARCHAR(50) NULL;
	v_customer_trx_amt NUMBER NULL;
    BEGIN
	SELECT customer_id INTO v_customer_id FROM bill_st.Customer
	WHERE customer_prodid = p_broker_number;
	EXCEPTION
	    WHEN too_many_rows THEN
		BEGIN
		    SELECT INVOICENUMBER, POLICYNUMBER, TRANSACTIONDOLLARAMOUNT
		    INTO v_customer_inv_num, v_customer_pol_num, v_customer_trx_amt
		    FROM bill_st.feed_transaction_payments a
		    WHERE a.filename = p_filename
		    AND a.brokernumber = p_broker_number AND CHECKNUMBEROFTHECHECK = p_check_number
		    AND TRANSACTIONDOLLARAMOUNT = p_check_amount
		    AND a.processed <> 1;
		END;
		--get by invoice # if not null
		BEGIN
		    SELECT c.customer_id INTO v_customer_id
		    FROM customer_bill a
		    JOIN customer_bill_item b ON b.bill_id = a.bill_id
		    JOIN customer c ON c.customer_id = a.customer_id
		    WHERE a.invoice_num = v_customer_inv_num
		    AND nvl(B.net_due_amt, 0) - nvl(B.tot_payments_applied_amt, 0) != 0
		    AND c.customer_prodid = p_broker_number;
		    EXCEPTION WHEN no_data_found THEN
			--get by pol # & amt
			BEGIN
			    SELECT c.customer_id INTO v_customer_id
			    FROM customer_bill a
			    JOIN customer_bill_item b ON b.bill_id = a.bill_id
			    JOIN customer c ON c.customer_id = a.customer_id
			    WHERE b.policy_number = v_customer_pol_num and net_due_amt = v_customer_trx_amt
			    AND nvl(B.net_due_amt, 0) - nvl(B.tot_payments_applied_amt, 0) != 0
			    AND c.customer_prodid = p_broker_number
			    AND trunc(A.payment_due_date) =
				(SELECT min(trunc(X.payment_due_date))
				 FROM customer_bill X JOIN customer_bill_item Y ON X.bill_id = Y.bill_id
				 JOIN customer Z ON X.customer_ID = Z.customer_ID
				 WHERE nvl(Y.net_due_amt, 0) - nvl(Y.tot_payments_applied_amt, 0) != 0
				 AND Y.policy_number = v_customer_pol_num
				 AND Y.net_due_amt = v_customer_trx_amt);
			END;
		END;
	    /*WHEN NO_DATA_FOUND THEN
		--process external account ?
		RETURN;*/

    END GetCustomer;

    PROCEDURE ProcessProducerExternalAcct(p_transaction_type IN VARCHAR, p_feed_row_id IN NUMBER)
    IS
	v_external_acct_customer_id NUMBER NULL;
	v_exclude_from_update NUMBER(1) := 0;
	v_external_acct_exists NUMBER(1) := 0;
	v_company_id NUMBER NULL;
    BEGIN
	IF feed_trx_payments_rec.brokernumber IS NOT NULL THEN
	    IF v_customer_id IS NULL THEN
		BEGIN
		    SELECT a.customer_id INTO v_external_acct_customer_id FROM customer a
		    WHERE a.customer_prodid = feed_trx_payments_rec.brokernumber;
		    EXCEPTION
			WHEN NO_DATA_FOUND THEN
			    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,feed_trx_payments_rec.filename, '', 'Customer record not found for broker #: '
				||feed_trx_payments_rec.brokernumber, '', SYSDATE);
			WHEN TOO_MANY_ROWS THEN
			    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,feed_trx_payments_rec.filename, '', 'More than one customer record found for broker #: '
				||feed_trx_payments_rec.brokernumber, '', SYSDATE);
			WHEN OTHERS THEN
			    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.ProcessProducerExternalAcct. Error retreiving customer record.'
				,feed_trx_payments_rec.filename, to_char(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
		END;
	    ELSE
		v_external_acct_customer_id := v_customer_id;
	    END IF;

	    CASE
		WHEN  upper(p_transaction_type) = 'CHK' THEN --Lockbox
		    BEGIN
			SELECT 1 INTO v_exclude_from_update FROM BILL_ST.PROD_EXTRNL_ACCT_EXCLUDE
			WHERE producer_id = feed_trx_payments_rec.brokernumber;
			EXCEPTION
			    WHEN NO_DATA_FOUND THEN
				BEGIN
				    SELECT 1 INTO v_external_acct_exists
				    FROM bill_st.producer_external_account a
				    JOIN bill_st.customer b ON a.customer_id = b.customer_id
				    WHERE aba_number = trim(feed_trx_payments_rec.transitroutingnumber)
				    AND account_number = trim(feed_trx_payments_rec.accountnumberofthecheck)
				    AND b.customer_prodid = feed_trx_payments_rec.brokernumber
				    AND upper(a.transaction_type) = 'CHK';
				    EXCEPTION
					WHEN NO_DATA_FOUND THEN
					    INSERT INTO bill_st.producer_external_account a
						(a.customer_id, a.aba_number,a.account_number,
						a.feed_transaction_payments_id,a.add_date, a.transaction_type)
					    VALUES
						(v_external_acct_customer_id, trim(feed_trx_payments_rec.transitroutingnumber),
						trim(feed_trx_payments_rec.accountnumberofthecheck), p_feed_row_id, SYSDATE,'CHK');
					WHEN OTHERS THEN
					    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.ProcessProducerExternalAcct. Error retreiving producer_external_account record.'
						,feed_trx_payments_rec.filename, to_char(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
				END;
			    WHEN OTHERS THEN
				BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.ProcessProducerExternalAcct.',feed_trx_payments_rec.filename,
				    to_char(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
		    END;
		WHEN  upper(p_transaction_type) = 'ACH' OR  upper(p_transaction_type) = 'WIRE' THEN
		    BEGIN
			SELECT account_number INTO v_company_id
			FROM bill_st.producer_external_account a
			JOIN bill_st.customer b ON a.customer_id = b.customer_id
			WHERE b.customer_prodid = feed_trx_payments_rec.brokernumber
			AND upper(a.transaction_type) IN ('ACH','WIRE');
			EXCEPTION
			    WHEN NO_DATA_FOUND THEN
				--insert new record
				INSERT INTO bill_st.producer_external_account a
				    (a.customer_id, a.account_number,
				    a.feed_transaction_payments_id,a.add_date, a.transaction_type)
				VALUES
				    (v_external_acct_customer_id, trim(feed_trx_payments_rec.accountnumberofthecheck),
				     p_feed_row_id, SYSDATE, upper(p_transaction_type));
			    WHEN OTHERS THEN
				BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.ProcessProducerExternalAcct. Error retreiving producer_external_account record.'
				    ,feed_trx_payments_rec.filename, to_char(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
		    END;
		    IF v_company_id IS NOT NULL AND (v_company_id <> feed_trx_payments_rec.accountnumberofthecheck) THEN
			    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,feed_trx_payments_rec.filename, '', 'Warning: The BoA Company ID: '
			    ||feed_trx_payments_rec.accountnumberofthecheck||' for broker #: '||feed_trx_payments_rec.brokernumber||', row ID: '||p_feed_row_id
			    ||' differs from existing Company ID: '||v_company_id||'. Please review.', '', SYSDATE);
		    END IF;
	    END CASE;
	END IF;
    END ProcessProducerExternalAcct;

    PROCEDURE InsertBillPayment(p_customer_id IN NUMBER, p_payment_type_id IN NUMBER, p_bank_account_id IN NUMBER, p_feed_row_id IN NUMBER)
    IS
	v_payment_customer_id NUMBER NULL;
    BEGIN

	IF p_customer_id IS NULL THEN
	    v_payment_customer_id := v_suspense_acct_customer_id;
	    v_valid_broker_payment := 0;
	ELSE
	    v_payment_customer_id := p_customer_id;
	    v_valid_broker_payment := 1;
	END IF;

	INSERT INTO bill_payment (customer_id, payment_type, payment_amt,
	payment_deposit_date, payment_applied_by,
	lastupdate_date, chk_ref_number, bank_acct_id, payment_entered_date, currency_id, currency_iso_code,
	exchange_rate, external_feed_id)
	VALUES
	(v_payment_customer_id, p_payment_type_id, feed_trx_payments_rec.transactiondollaramount,
	to_date(feed_trx_payments_rec.depositdate, 'dd-mon-yyyy'), program_name,
	sysdate, feed_trx_payments_rec.checknumberofthecheck, p_bank_account_id, sysdate, 1, 'USD',
	1, p_feed_row_id)
	returning payment_id INTO v_payment_id;

	EXCEPTION WHEN others THEN
	    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.InsertBillPayment.',feed_trx_payments_rec.filename,
		to_char(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);

    END InsertBillPayment;

    PROCEDURE ProcessReceivable
    IS
	v_combined_invoice_parent NUMBER NULL;

    CURSOR feed_trx_receivables IS
    SELECT a.id, a.filename, a.fileprocesseddatetime,
       a.filecreationdatetime, a.destinationdda, a.accountnumber,
       a.depositdate, a.totalchecks, a.totaldollarsamount,
       a.batchnumber, a.batchtransactionscount, a.itemnumber,
       a.transactiondollaramount, a.transitroutingnumber,
       a.accountnumberofthecheck, a.checknumberofthecheck,
       a.invoiceamount, a.brokernumber, a.invoicenumber, a.policynumber,
       a.sequencenumber, a.processed, a.processeddatetime,
       a.transactiontype
    FROM bill_st.feed_transaction_payments a
    WHERE a.filename = feed_trx_payments_rec.filename
    AND a.checknumberofthecheck = feed_trx_payments_rec.checknumberofthecheck;

    BEGIN
	--add loop thru cursor
	FOR feed_receivable IN feed_trx_receivables LOOP
	    --query for a receivable
	    IF feed_receivable.invoicenumber IS NOT NULL THEN
		--check if combined invoice
		BEGIN
		    SELECT DISTINCT A.PARENT_POLICY_TRX_ID INTO v_combined_invoice_parent
		    FROM dw_st.ar_combined_invoice A
		    WHERE A.PARENT_POLICY_TRX_ID = feed_receivable.invoicenumber
		    AND A.policy_number = feed_receivable.policynumber
		    AND A.transaction_id =
			(SELECT MAX(z.transaction_id) FROM dw_st.ar_combined_invoice z
			 WHERE z.PARENT_POLICY_TRX_ID = feed_receivable.policynumber);
		    EXCEPTION
			WHEN no_data_found THEN v_combined_invoice_parent := NULL;
		END;
		IF v_combined_invoice_parent IS NOT NULL THEN
		    CombinedInvoices(v_combined_invoice_parent, feed_receivable.policynumber,
			feed_receivable.transactiondollaramount, feed_receivable.invoiceamount,
			feed_receivable.depositdate, feed_receivable.checknumberofthecheck,
			feed_receivable.brokernumber, feed_receivable.id);
		ELSE
		    --level 1: match for receivable by invoice #
		    BEGIN
			GetReceivableByInvoiceNum(to_char(feed_receivable.invoicenumber));
			EXCEPTION
			    WHEN no_data_found THEN
				IF feed_receivable.policynumber IS NOT NULL THEN
				    BEGIN
					--level 2: match on policy #, amt & oldest due dt when multiple open receivables
					GetReceivableByPolicyNumber(feed_receivable.policynumber, feed_receivable.TRANSACTIONDOLLARAMOUNT);
					EXCEPTION
					    WHEN no_data_found THEN
						BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,feed_trx_payments_rec.filename, '', 'Receivable not found for feed invoice #: '
						    ||feed_receivable.invoicenumber||'or policy #: '||feed_receivable.policynumber
						    ||', trx amoumt: '||feed_receivable.TRANSACTIONDOLLARAMOUNT, '', SYSDATE);
					    WHEN others THEN
						BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.GetReceivableByPolicyNumber on query for receivable.',feed_trx_payments_rec.filename,
						    to_char(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
				    END;
				ELSE
				    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,feed_trx_payments_rec.filename, '', 'Missing/invalid invoice or policy # for file: '||feed_receivable.filename||
					' , row ID: '||feed_receivable.id, '', SYSDATE);
				END IF;
			    WHEN others THEN
				BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.GetReceivableByInvoiceNum on query for receivable.', v_filename,
				    to_char(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
		    END;
		END IF;
	    ELSIF feed_receivable.policynumber IS NOT NULL THEN
		BEGIN
		    --level 2: match on policy #, amt & oldest due dt when multiple open receivables
		    GetReceivableByPolicyNumber(feed_receivable.policynumber, feed_receivable.TRANSACTIONDOLLARAMOUNT);
		    EXCEPTION
			WHEN no_data_found THEN
			    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,feed_trx_payments_rec.filename, '', 'Receivable not found for feed invoice #: '
				||feed_receivable.invoicenumber||'or policy #: '||feed_receivable.policynumber
				||', trx amoumt: '||feed_receivable.TRANSACTIONDOLLARAMOUNT, '', SYSDATE);
			WHEN others THEN
			    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.GetReceivableByPolicyNumber on query for receivable.',feed_trx_payments_rec.filename,
				to_char(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
		END;
	    ELSE
		BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,feed_trx_payments_rec.filename, '', 'Invoice & policy # not provided for file: '||feed_receivable.filename||
		    ' , row ID: '||feed_receivable.id, '', SYSDATE);
	    END IF;

	    --if a receivable is found, apply the payment
	    IF v_bill_item_id IS NOT NULL THEN
		ApplyPayment(feed_receivable.invoiceamount, feed_receivable.depositdate,
		    feed_receivable.checknumberofthecheck , feed_receivable.brokernumber, feed_receivable.id, feed_receivable.invoicenumber);
	    END IF;
	    UpdateFeedTransactionPayments(feed_receivable.id);
	END LOOP;

    END ProcessReceivable;

    PROCEDURE CombinedInvoices(p_combined_invoice_parent IN NUMBER, p_policy_number IN VARCHAR,
	p_transaction_dollar_amount IN VARCHAR, p_invoice_amount IN NUMBER, p_deposit_date IN DATE,
	p_check_number IN VARCHAR, p_broker_number IN NUMBER, p_feed_row_id IN NUMBER)
    IS
	v_total_net_due_amt NUMBER := 0;

    BEGIN
	--get the total net amt due then compare to the feed trx net amt due
	SELECT SUM(net_due_amt) INTO v_total_net_due_amt FROM
	    (SELECT sum(nvl(B.net_due_amt,0)) AS net_due_amt
	     FROM customer_bill A JOIN customer_bill_item B ON A.bill_id = B.bill_id
	     JOIN customer C ON A.customer_ID = C.customer_ID
	     WHERE nvl(B.net_due_amt, 0) - nvl(B.tot_payments_applied_amt, 0) != 0
	     AND a.invoice_num IN (
		SELECT to_char(child_policy_trx_id)
		FROM dw_st.ar_combined_invoice A
		WHERE A.PARENT_POLICY_TRX_ID = p_combined_invoice_parent
		AND A.policy_number = p_policy_number
		AND A.transaction_id =
		    (SELECT MAX(z.transaction_id) FROM dw_st.ar_combined_invoice z
		     WHERE z.policy_number = p_policy_number))
	     UNION
	     SELECT nvl(B.net_due_amt,0) AS net_due_amt
	     FROM customer_bill A JOIN customer_bill_item B ON A.bill_id = B.bill_id
	     JOIN customer C ON A.customer_ID = C.customer_ID
	     WHERE nvl(B.net_due_amt, 0) - nvl(B.tot_payments_applied_amt, 0) != 0
	     AND a.invoice_num IN (p_combined_invoice_parent));
	EXCEPTION
	    WHEN others THEN
		BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.CombinedInvoices. ', v_filename, to_char(SQLCODE), 'Message: '
		    || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);

	IF v_total_net_due_amt = p_transaction_dollar_amount THEN
	    --pay the parent receivable
	    BEGIN
		GetReceivableByInvoiceNum(to_char(p_combined_invoice_parent));
		EXCEPTION
		    WHEN no_data_found THEN
			BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name, v_filename, '', 'PROCESS_BOA_FEED.CombinedInvoices: Receivable not found for feed invoice #: '||
			    p_combined_invoice_parent, '', SYSDATE);
		    WHEN others THEN
			BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.CombinedInvoices on query for receivable.', v_filename,
			    to_char(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
	    END;
	    ApplyPayment(p_invoice_amount, p_deposit_date,
		    p_check_number , p_broker_number, p_feed_row_id, p_combined_invoice_parent);
	    UpdateARCombinedInvoice(p_policy_number, p_combined_invoice_parent, 'P');
	    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,feed_trx_payments_rec.filename, '', 'Receivable paid for feed invoice #: '
		||p_combined_invoice_parent
		||' with check #: '||p_check_number
		||', trx amoumt: '||p_invoice_amount
		||' from broker #: '||p_broker_number, '', SYSDATE);

	    --pay the child receivable(s)
	    ProcessChildInvoices(to_char(p_combined_invoice_parent), p_policy_number, p_invoice_amount,
		p_deposit_date, p_check_number, p_broker_number, p_feed_row_id);
	    UpdateARCombinedInvoice(p_policy_number, p_combined_invoice_parent, 'C');
	ELSE
	    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name, v_filename, '', 'Feed invoice amt not equal to combined invoice amt for broker#: '||p_broker_number||
		', Check/Ref. #: '||p_check_number||', Deposit Date: '||p_deposit_date||
		', Invoice Amt: '||p_invoice_amount||', Policy #: '||p_policy_number||
		', Invoice #: '||p_combined_invoice_parent, '', SYSDATE);
	    RETURN;
	END IF;

    END CombinedInvoices;

    PROCEDURE ProcessChildInvoices(p_combined_invoice_parent IN VARCHAR2, p_policy_number IN VARCHAR,
	p_invoice_amount IN NUMBER, p_deposit_date IN DATE, p_check_number IN VARCHAR, p_broker_number IN NUMBER, p_feed_row_id IN NUMBER)
    IS
	CURSOR c_child_invoices IS
	    SELECT to_char(child_policy_trx_id) AS child_policy_trx_id
	    FROM dw_st.ar_combined_invoice A
	    WHERE A.PARENT_POLICY_TRX_ID = p_combined_invoice_parent
	    AND A.policy_number = p_policy_number
	    AND A.transaction_id =
		(SELECT MAX(z.transaction_id) FROM dw_st.ar_combined_invoice z
		 WHERE z.policy_number = p_policy_number);
    BEGIN
	FOR child_invoice IN c_child_invoices LOOP
	    BEGIN
		GetReceivableByInvoiceNum(to_char(child_invoice.child_policy_trx_id));
		EXCEPTION
		    WHEN no_data_found THEN
			BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name, v_filename, '', 'PROCESS_BOA_FEED.ProcessChildInvoices: Receivable not found for feed invoice #: '||
			    child_invoice.child_policy_trx_id, '', SYSDATE);
		    WHEN others THEN
			BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.ProcessChildInvoices on query for receivable.', v_filename,
			    to_char(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
	    END;
	    ApplyPayment(p_invoice_amount, p_deposit_date,
		    p_check_number , p_broker_number, p_feed_row_id, child_invoice.child_policy_trx_id);
	    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,feed_trx_payments_rec.filename, '', 'Receivable paid for feed invoice #: '
		||child_invoice.child_policy_trx_id
		||' with check #: '||p_check_number
		||', trx amoumt: '||p_invoice_amount
		||' from broker #: '||p_broker_number, '', SYSDATE);
	END LOOP;
    END ProcessChildInvoices;

    PROCEDURE GetReceivableByInvoiceNum (p_invoice_number IN VARCHAR2)
    IS
    BEGIN

	SELECT B.bill_item_id AS bill_item_id, nvl(B.net_due_amt,0)-nvl(B.tot_payments_applied_amt,0) AS BALANCE,
	nvl(B.net_due_amt,0) AS net_due_amt,nvl(B.tot_payments_applied_amt,0) AS tot_payments_applied_amt,
	A.customer_ID, a.bill_id, A.invoice_num, B.policy_number
	INTO v_bill_item_id, v_balance, v_net_due_amt, v_tot_payments_applied_amt, v_customer_ID, v_bill_id,
	     v_invoice_number, v_policy_number
	FROM customer_bill A JOIN customer_bill_item B ON A.bill_id = B.bill_id
	JOIN customer C ON A.customer_ID = C.customer_ID
	WHERE nvl(B.net_due_amt, 0) - nvl(B.tot_payments_applied_amt, 0) != 0
	AND a.invoice_num = p_invoice_number
	ORDER BY net_due_amt;

    END GetReceivableByInvoiceNum;

    PROCEDURE GetReceivableByPolicyNumber(p_policy_number IN VARCHAR2, p_transaction_amt IN NUMBER)
    IS
    BEGIN

	SELECT B.bill_item_id AS bill_item_id, nvl(B.net_due_amt,0)-nvl(B.tot_payments_applied_amt,0) AS BALANCE,
	nvl(B.net_due_amt,0) AS net_due_amt,nvl(B.tot_payments_applied_amt,0) AS tot_payments_applied_amt,
	A.customer_ID, a.bill_id, A.invoice_num, B.policy_number
	INTO v_bill_item_id, v_balance, v_net_due_amt, v_tot_payments_applied_amt, v_customer_ID, v_bill_id,
	     v_invoice_number, v_policy_number
	FROM customer_bill A JOIN customer_bill_item B ON A.bill_id = B.bill_id
	JOIN customer C ON A.customer_ID = C.customer_ID
	WHERE nvl(B.net_due_amt, 0) - nvl(B.tot_payments_applied_amt, 0) != 0
	AND B.policy_number = p_policy_number
	ORDER BY A.payment_due_date ASC;

	EXCEPTION
	    WHEN too_many_rows THEN
		BEGIN
		    SELECT B.bill_item_id AS bill_item_id, nvl(B.net_due_amt,0)-nvl(B.tot_payments_applied_amt,0) AS BALANCE,
		    nvl(B.net_due_amt,0) AS net_due_amt,nvl(B.tot_payments_applied_amt,0) AS tot_payments_applied_amt,
		    A.customer_ID, a.bill_id, A.invoice_num, B.policy_number
		    INTO v_bill_item_id, v_balance, v_net_due_amt, v_tot_payments_applied_amt, v_customer_ID, v_bill_id,
			 v_invoice_number, v_policy_number
		    FROM customer_bill A JOIN customer_bill_item B ON A.bill_id = B.bill_id
		    JOIN customer C ON A.customer_ID = C.customer_ID
		    WHERE nvl(B.net_due_amt, 0) - nvl(B.tot_payments_applied_amt, 0) != 0
		    AND B.policy_number = p_policy_number
		    AND B.net_due_amt = p_transaction_amt
		    AND trunc(A.payment_due_date) =
			(SELECT min(trunc(X.payment_due_date))
			 FROM customer_bill X JOIN customer_bill_item Y ON X.bill_id = Y.bill_id
			 JOIN customer Z ON X.customer_ID = Z.customer_ID
			 WHERE nvl(Y.net_due_amt, 0) - nvl(Y.tot_payments_applied_amt, 0) != 0
			 AND Y.policy_number = p_policy_number
			 AND Y.net_due_amt = p_transaction_amt);
		END;

    END GetReceivableByPolicyNumber;

    PROCEDURE ApplyPayment(p_invoice_amount IN NUMBER, p_deposit_date IN DATE,
	p_check_number IN VARCHAR, p_broker_number IN NUMBER, p_feed_row_id IN NUMBER, p_invoice_number IN VARCHAR)
    IS
	--v_payment_id NUMBER NULL;
	v_remaining_payment FLOAT NULL;
	v_total_used_payment FLOAT NULL;
	out_payment_applied_id NUMBER NULL;
    BEGIN
	BEGIN
	    --query for bill payment
	    SELECT payment_id, nvl(A.payment_amt, 0) - nvl(A.payment_applied_amt, 0), nvl(A.payment_applied_amt, 0)
	    INTO v_payment_id, v_remaining_payment, v_total_used_payment
	    FROM bill_payment A JOIN customer B ON A.customer_id = B.customer_id
	    WHERE A.payment_id = v_payment_id;

	    EXCEPTION
		WHEN no_data_found THEN
		    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name, v_filename, '', 'Payment not found for payment id #: '||v_payment_id
			, '', SYSDATE);
		    RETURN;
		WHEN others THEN
		    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.ProcessReceivable on query for bill paymenet.', v_filename,
			to_char(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
		    RETURN;
	END;
	IF v_remaining_payment - v_balance >= 0 THEN
	    IF p_invoice_amount >= v_net_due_amt THEN
		v_remaining_payment := v_remaining_payment - v_balance;
		BEGIN
		    UPDATE bill_payment
		    SET payment_applied_amt = nvl(payment_applied_amt, 0) + nvl(v_balance, 0), payment_applied_by = program_name,
		    lastupdate_date = sysdate
		    WHERE payment_id = v_payment_id;

		    EXCEPTION
			WHEN others THEN
			    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.ProcessReceivable on update for bill paymenet.', v_filename,
				to_char(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
			    RETURN;
		END;

		v_total_used_payment := v_total_used_payment + v_balance;
		BEGIN
		    out_payment_applied_id := InsertIntoPaymentApplied(v_bill_item_id, v_payment_id, v_balance, program_name,
			NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
		    UpdateCustomerBillItem(v_balance, NULL, v_bill_item_id, program_name, p_feed_row_id);
		    UpdateCustomerBill(v_bill_id, 'Paid', program_name);

		    EXCEPTION
			WHEN others THEN
			    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.ProcessReceivable.', v_filename,
				to_char(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
			    RETURN;
		END;
	    ELSE
		BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name, v_filename, '', 'Feed invoice amt is less than bill net due for broker#: '||p_broker_number||
			', Check/Ref. #: '||p_check_number||', Deposit Date: '||p_deposit_date||
			', Invoice Amt: '||p_invoice_amount||', Policy #: '||v_policy_number
			, '', SYSDATE);
		RETURN;
	    END IF;
	ELSE
	    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name, v_filename, '', 'Payment balance does not cover invoice amt for Broker #: '||p_broker_number||
			', Check/Ref. #: '||p_check_number||', Deposit Date: '||p_deposit_date||
			', Invoice Amt: '||p_invoice_amount||', Policy #: '||v_policy_number
			, '', SYSDATE);
	    RETURN;
	END IF;
	BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG(program_name,v_filename, '', 'Receivable paid for feed invoice #: '
		    ||p_invoice_number||', policy #: '||v_policy_number
		    ||' with check #: '||p_check_number
		    ||', Invoice Amt: '||p_invoice_amount
		    ||' from broker #: '||p_broker_number, '', SYSDATE);
    END ApplyPayment;

    PROCEDURE UpdateCustomerBillItem
    (
	in_applied_amount IN NUMBER,
	in_applied_amount_usd IN NUMBER DEFAULT NULL,
	in_bill_item_id IN NUMBER,
	in_user IN VARCHAR2,
	in_feed_row_id IN NUMBER,
	in_payment_id IN NUMBER DEFAULT NULL, -- used for fx on foreign currency
	in_payment_applied_id IN NUMBER DEFAULT NULL -- used for fx on foreign currency
    )
    IS
	test NUMBER := 0;
	v_exchange_rate FLOAT;
	v_currency_id NUMBER;
	v_balance NUMBER;
	v_fx NUMBER;
    BEGIN
	SELECT nvl(currency, 1) INTO v_currency_id FROM customer_bill_item WHERE bill_item_id = in_bill_item_id;
	IF v_currency_id = 1 THEN -- USD
	    UPDATE customer_bill_item SET tot_payments_applied_amt = nvl(tot_payments_applied_amt, 0) + in_applied_amount, lastupdate_date = sysdate,
	    lastupdate_by = in_user, invoice_status = DECODE(net_due_amt, nvl(tot_payments_applied_amt, 0) + in_applied_amount, 'COMPLETE', invoice_status),
	    external_feed_id = in_feed_row_id
	    WHERE bill_item_id = in_bill_item_id;
	ELSE -- foreign currency
	    IF in_applied_amount_usd IS NULL OR in_applied_amount = 0 THEN
		v_exchange_rate := SQL_STATEMENTS_FOR_AR_APP.get_exchange_rate(v_currency_id);
	    ELSE
		v_exchange_rate := round(in_applied_amount_usd / in_applied_amount, 10);
	    END IF;
	    UPDATE customer_bill_item SET tot_payments_applied_amt_orig = nvl(tot_payments_applied_amt_orig, 0) + in_applied_amount,
	    tot_payments_applied_amt = nvl(tot_payments_applied_amt, 0) + CASE WHEN in_applied_amount_usd IS NULL THEN
	    round(in_applied_amount * v_exchange_rate, 2) ELSE in_applied_amount_usd END, lastupdate_date = sysdate,
	    lastupdate_by = in_user, invoice_status = DECODE(net_due_amount_original, nvl(tot_payments_applied_amt_orig, 0) +
	    in_applied_amount, 'COMPLETE', invoice_status), external_feed_id = in_feed_row_id
	    WHERE bill_item_id = in_bill_item_id
	    returning net_due_amount_original - tot_payments_applied_amt_orig, net_due_amt - tot_payments_applied_amt
	    INTO v_balance, v_fx;

	    IF v_balance = 0 THEN
		UPDATE customer_bill_item SET total_fx_amount = nvl(total_fx_amount, 0) + v_fx WHERE bill_item_id = in_bill_item_id;
		UPDATE bill_payment SET total_fx_amount = nvl(total_fx_amount, 0) + v_fx WHERE payment_id = in_payment_id;
		UPDATE payment_applied SET fx_amount = v_fx WHERE payment_applied_id = in_payment_applied_id;
	    END IF;

	END IF;
	EXCEPTION
	    WHEN others THEN
		BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.UpdateCustomerBillItem. ', v_filename, to_char(SQLCODE), 'Message: '
		    || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);

    END UpdateCustomerBillItem;

    PROCEDURE UpdateCustomerBill
    (
	in_bill_id IN NUMBER,
	in_bill_status IN VARCHAR2,
	in_user IN VARCHAR2
    )
    IS
    BEGIN

	UPDATE customer_bill SET BILL_STATUS = in_bill_status, LASTupdate_DATE = SYSDATE, LASTupdate_BY = in_user WHERE bill_id = in_bill_id;
	COMMIT;
	EXCEPTION
	    WHEN others THEN
		BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.UpdateCustomerBill', v_filename,
		    TO_CHAR(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);

    END UpdateCustomerBill;

    PROCEDURE UpdateFeedTransactionPayments(p_filename IN VARCHAR, p_checknumber IN VARCHAR)
    IS

    BEGIN
	UPDATE bill_st.feed_transaction_payments A
	SET A.processed = 1, a.processeddatetime = sysdate
	WHERE A.filename = p_filename AND A.checknumberofthecheck = p_checknumber;

	EXCEPTION
	    WHEN others THEN
		BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.UpdateFeedTransactionPayments.', v_filename,
		    TO_CHAR(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
    END UpdateFeedTransactionPayments;

    PROCEDURE UpdateFeedTransactionPayments(p_row_id IN NUMBER)
    IS

    BEGIN
	UPDATE bill_st.feed_transaction_payments A
	SET A.processed = 1, a.processeddatetime = sysdate
	WHERE A.id = p_row_id;

	EXCEPTION
	    WHEN others THEN
		BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.UpdateFeedTransactionPayments.', v_filename,
		    to_char(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
    END UpdateFeedTransactionPayments;

    PROCEDURE UpdateARCombinedInvoice(p_policy_num IN NUMBER, p_policy_trx_id IN NUMBER, p_policy_trx_type IN VARCHAR2)
    IS
    BEGIN
	IF p_policy_trx_type = 'P' THEN --update parent
	    BEGIN
		UPDATE dw_st.ar_combined_invoice A
		SET A.processed = 1, a.processed_date = sysdate
		WHERE A.POLICY_NUMBER = p_policy_num
		AND A.PARENT_POLICY_TRX_ID = p_policy_trx_id
		AND A.transaction_id =
		    (SELECT MAX(z.transaction_id) FROM dw_st.ar_combined_invoice z
		     WHERE z.policy_number = p_policy_num);

		EXCEPTION
		    WHEN others THEN
			BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.UpdateARCombinedInvoice for parent.', v_filename,
			    to_char(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
	    END;
	ELSE --update children
	    BEGIN
		UPDATE dw_st.ar_combined_invoice A
		SET A.processed = 1, a.processed_date = sysdate
		WHERE A.POLICY_NUMBER = p_policy_num
		AND A.CHILD_POLICY_TRX_ID = p_policy_trx_id
		AND A.transaction_id =
		    (SELECT MAX(z.transaction_id) FROM dw_st.ar_combined_invoice z
		     WHERE z.policy_number = p_policy_num);

		EXCEPTION
		    WHEN others THEN
			BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.UpdateARCombinedInvoice for children.', v_filename,
			    to_char(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);
	    END;
	END IF;
    END UpdateARCombinedInvoice;

    FUNCTION InsertIntoPaymentApplied
    (
	in_bill_item_id IN NUMBER,
	in_payment_id IN NUMBER,
	in_applied_amount IN FLOAT,
	in_user IN VARCHAR2,
	in_credit IN VARCHAR2,
	in_credit_reason IN VARCHAR2,
	in_credit_date IN VARCHAR2,
	in_credit_reference_number IN VARCHAR2,
	in_refund IN VARCHAR2,
	in_refund_reason IN VARCHAR2,
	in_refund_date IN VARCHAR2,
	in_reallocated_bill_item_id IN NUMBER,
	in_payment_comment IN VARCHAR2,
	in_currency_id IN NUMBER DEFAULT 1,
	in_fx_amount FLOAT DEFAULT 0,
	in_applied_amount_usd IN FLOAT DEFAULT NULL
    )
    RETURN NUMBER AS
	v_exchange_rate FLOAT := 1;
	v_payment_amt FLOAT;
	v_net_due_amount FLOAT;
	v_payment_applied_id NUMBER := NULL;
    BEGIN
	IF nvl(in_currency_id, 1) = 1 THEN -- USD
	    INSERT INTO PAYMENT_APPLIED (bill_item_id, PAYMENT_ID, PAYMENT_APPLIED_AMT, PAYMENT_APPLIED_DATE, PAYMENT_APPLIED_BY,
	    CREDIT, CREDIT_REASON, CREDIT_DATE, CRDT_REF_CHECK_NUM, REFUND, REFUND_REASON, REFUND_DATE,
	    REALLOCATED_bill_item_id, PAYMENT_COMMENT, LASTupdate_DATE, exchange_rate)
	    VALUES (in_bill_item_id, in_payment_id, in_applied_amount, SYSDATE, in_user, in_credit, in_credit_reason, to_date(in_credit_date,'mm/dd/yyyy'),
	    in_credit_reference_number, in_refund, in_refund_reason, to_date(in_refund_date,'mm/dd/yyyy'), in_reallocated_bill_item_id,
	    in_payment_comment, SYSDATE, 1) returning payment_applied_id INTO v_payment_applied_id;
	ELSE
	    IF in_applied_amount_usd IS NULL THEN
		v_exchange_rate := SQL_STATEMENTS_FOR_AR_APP.get_exchange_rate(in_currency_id);
	    ELSE
		v_exchange_rate := round(in_applied_amount_usd / in_applied_amount, 4);
	    END IF;

	    INSERT INTO PAYMENT_APPLIED (bill_item_id, PAYMENT_ID, PAYMENT_APPLIED_AMT_original, PAYMENT_APPLIED_DATE, PAYMENT_APPLIED_BY,
	    CREDIT, CREDIT_REASON, CREDIT_DATE, CRDT_REF_CHECK_NUM, REFUND, REFUND_REASON, REFUND_DATE, REALLOCATED_bill_item_id,
	    PAYMENT_COMMENT, LASTupdate_DATE, exchange_rate, PAYMENT_APPLIED_Amt, fx_amount)
	    VALUES (in_bill_item_id, in_payment_id, in_applied_amount, SYSDATE, in_user, in_credit, in_credit_reason, to_date(in_credit_date,'mm/dd/yyyy'),
	    in_credit_reference_number, in_refund, in_refund_reason, to_date(in_refund_date,'mm/dd/yyyy'), in_reallocated_bill_item_id,
	    in_payment_comment, SYSDATE, v_exchange_rate, CASE WHEN in_applied_amount_usd IS NOT NULL THEN round(in_applied_amount_usd, 2) ELSE
	    round((in_applied_amount * v_exchange_rate) + nvl(in_fx_amount, 0), 2) END, round(nvl(in_fx_amount, 0), 2))
	    returning payment_applied_id INTO v_payment_applied_id;
	END IF;

    RETURN v_payment_applied_id;

    EXCEPTION
	WHEN others THEN
	    BILL_ST.P_WRITE_TO_AR_STORED_PROC_LOG('PROCESS_BOA_FEED.InsertIntoPaymentApplied.', v_filename,
		TO_CHAR(SQLCODE), 'Message: ' || SQLERRM, DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, SYSDATE);

    END InsertIntoPaymentApplied;

END PROCESS_BOA_FEED;
/

