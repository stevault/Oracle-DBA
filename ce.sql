
WITH polcov AS (
    SELECT  x.ENTITY_REFERENCE ,
            x.COVERAGE_TYPE ,
            SUM(NVL(x.TRANSACTION_PREMIUM,0)) AS WRITTEN_PREMIUM ,
            MAX(NVL(x.LIMIT, 0)) AS LIMIT ,
            MIN(NVL(x.DEDUCTIBLE, 0)) AS DEDUCTIBLE
    FROM (             
    SELECT  c.ENTITY_REFERENCE ,
            c.COVERAGE_CODE ,
            CASE WHEN c.COVERAGE_CODE IN ( 'GA-LIAB-BTM', 'LIAB-DISCOUNT',
                                             'FELLOW-EMPLOYEE', 'REG-LIAB',
                                             'DOC-LIAB', 'LIAB', 'HBA-LIABPD',
                                             'DOC-LIABPD', 'LIABPD', 'MEX-COV',
                                             'VEH-LIM-LIABPD', 'POLLUT',
                                             'VEH-PPI', 'HBA-LIABPD-BTM' )
                 THEN 'AULIABILITY'
                 WHEN c.COVERAGE_CODE IN ( 'MEDICAL-BENE', 'REG-MEDPAY',
                                             'DOC-MEDPAY', 'MEDPAY' )
                 THEN 'AUMEDPAY'
                 WHEN c.COVERAGE_CODE IN ( 'GAP-COLL', 'GK-COLL',
                                             'TRLR-COLL', 'DOC-COLL', 'COLL',
                                             'REPO-COLL', 'AUTOHFSCOL' )
                 THEN 'AUPDCOLL'
                 WHEN c.COVERAGE_CODE IN ( 'ADDL-INS-PREM', 'SOUND',
                                             'GAP-OTC', 'GK-OTC', 'OTC',
                                             'DOC-OTC', 'TRLR-OTC',
                                             'FUNERAL-BENE', 'LOSS-OF-USE',
                                             'TAPES', 'TOWING', '' )
                 THEN 'AUPDCOMP'
                 WHEN c.COVERAGE_CODE IN ( 'HA-COLL', 'HA-OTC',
                                             'HA-LIAB-BAL-MIN',
                                             'HA-PD-BAL-MIN', 'ENO-LIAB',
                                             'HA-LIAB', 'ENO-MEDPAY',
                                             'NOL-OTSOC-BI', 'NOL-OTSOC-PD',
                                             'ENO-EXTEND', 'HA-UIM', 'ENO-UIM',
                                             'HA-UM', 'ENO-UM' )
                 THEN 'AUPDCOMP'
                 WHEN c.COVERAGE_CODE IN ( 'AFPB', 'APIP', 'FPB', 'BRD_FPB',
                                             'CFPB', 'EPIP', 'EMB', 'INCLOSS',
                                             'LEASED-WORKERS', 'BRD-PIP',
                                             'OBEL', 'PED-PIP', 'PIP',
                                             'REG-PIP', 'INCOME-BENE' )
                 THEN 'AUPIPP'
                 WHEN c.COVERAGE_CODE IN ( 'RENT-COLL', 'RENT-MA',
                                             'RENT-OTC' ) 
                THEN 'AUPDCOMP'
                 WHEN c.COVERAGE_CODE IN ( 'REG-UIM', 'UIM', 'DOC-UIM' )
                 THEN 'AUUIMP'
                 WHEN c.COVERAGE_CODE IN ( 'REG-UM', 'DOC-UM', 'UM', 'UMPD',
                                             'DOC-UMPD' ) THEN 'AUUMP'
            END AS COVERAGE_TYPE,
            SUM(c.TRANSACTION_PREMIUM) AS TRANSACTION_PREMIUM ,
            MAX(NVL(c.LIMIT, 0)) AS LIMIT ,
            MIN(NVL(c.DEDUCTIBLE, 0)) AS DEDUCTIBLE
    FROM    MIC_POLICY_AW.RT_MIS_CA_ALL_COVERAGES c
            INNER JOIN MIC_POLICY_AW.RT_MIS_QUOTE_POLICIES pol ON c.ENTITY_REFERENCE = pol.ENTITY_REFERENCE
    WHERE   1 = 1
    --AND c.ENTITY_REFERENCE LIKE 'PAUCA000000185%'
    --AND DATE_MODIFIED > (SYSDATE - INTERVAL '24' HOUR)
                        AND DISPLAY_POLICY_NUMBER IN ( '6000-0120', '6000-0344',
                                                       '6000-0293', '6000-0340',
                                                       '6000-0316', '6000-0250',
                                                       '6000-0185', '6000-0346',
                                                       '6000-0341', '6000-0331',
                                                       '6000-0364' )
    AND c.COVERAGE_CODE IN ('AFPB','ADDL-INS-PREM','APIP','SOUND','GA-LIAB-BTM',
                                'GAP-COLL','GAP-OTC','FPB','BRD_FPB','LIAB-DISCOUNT',
                                'GK-COLL','TRLR-COLL','DOC-COLL','COLL','HA-COLL',
                                'CFPB','HA-OTC','GK-OTC','OTC','DOC-OTC','TRLR-OTC',
                                'REPO-COLL','AUTOHFSCOL','EPIP','EMB','FELLOW-EMPLOYEE',
                                'FUNERAL-BENE','HA-LIAB-BAL-MIN','HA-PD-BAL-MIN','INCLOSS',
                                'LEASED-WORKERS','ENO-LIAB','REG-LIAB','HA-LIAB','DOC-LIAB',
                                'LIAB','HBA-LIABPD','DOC-LIABPD','LIABPD','MEX-COV',
                                'VEH-LIM-LIABPD','LOSS-OF-USE','MEDICAL-BENE','MEDPAY',
                                'REG-MEDPAY','DOC-MEDPAY','ENO-MEDPAY','BRD-PIP','NOL-OTSOC-BI',
                                'NOL-OTSOC-PD','ENO-EXTEND','OBEL','PED-PIP','PIP','REG-PIP',
                                'POLLUT','VEH-PPI','RENT-COLL','RENT-MA','RENT-OTC','TAPES',
                                'TOWING','HA-UIM','REG-UIM','ENO-UIM','UIM','DOC-UIM','REG-UM',
                                'HA-UM','DOC-UM','UM','ENO-UM','UMPD','DOC-UMPD','INCOME-BENE',
                                'HBA-LIABPD-BTM')
    GROUP BY c.ENTITY_REFERENCE ,
            c.COVERAGE_CODE) x
    GROUP BY x.ENTITY_REFERENCE ,
            x.COVERAGE_TYPE
    ORDER BY ENTITY_REFERENCE, COVERAGE_TYPE
)
SELECT  DISTINCT pol.GID ,
				pol.entity_reference ,
        pol.DATE_CREATED ,
        pol.DATE_MODIFIED ,				
				pol.DISPLAY_POLICY_NUMBER AS PolicyNumber ,
				CASE pol.PRODUCT_CODE
					WHEN 'CA' THEN 'Casualty AL'
					WHEN 'GL' THEN 'Casualty GL'
					ELSE pol.PRODUCT_CODE
					END AS ProductCode ,
				subs.DATE_CREATED AS SubmissionEnteredDate ,
				0 AS PriorPendingLitigation ,
				NULL AS PriorPendingLitigationDate ,
				pol.EFFECTIVE_DATE AS PolicyEffectiveDate ,
				pol.EXPIRATION_DATE AS PolicyExpirationDate ,
				NULL AS PolicyRetroDate ,
				'Primary' AS CoverageLayer ,
				NULL AS AttachmentPoint ,
				NULL AS StackedOverPolicyNumber ,
				NULL AS StackedOverSubmissionNumber ,
				CASE pol.COMPANY_CODE 
					WHEN 'AC' THEN 'AWAC'
					WHEN 'IC' THEN 'AWIC'
					WHEN 'NA' THEN 'AWNAC'
					WHEN 'DN' THEN 'DNA'
					WHEN 'AU' THEN 'AWAU'
					WHEN 'DS' THEN 'DSI'
          WHEN 'SI' THEN 'AWSIC'
          ELSE pol.COMPANY_CODE 
				END AS IssuingCompany ,
				CASE 
					WHEN SUBSTR(pol.ENTITY_REFERENCE,15,1) != '0'
						AND pol.TRANSACTION_ACTION ='renewPolicy' THEN DISPLAY_POLICY_NUMBER
					ELSE NULL
				END AS ExpiringPolicyNumber ,
				0 AS PremiumFinanced ,
				1 AS BillingFrequency ,
				2 AS BillingMethod ,
				0 AS AuditablePolicy ,
				insureds.ID AS InsuredId ,
				insureds.BUSINESS_NAME AS InsuredName ,
				insured_addresses.LINE_1 AS InsuredAddressLine1 ,
				insured_addresses.LINE_2 AS InsuredAddressLine2 ,
				NULL AS InsuredAddressLine3 ,
				insured_addresses.CITY AS InsuredCity ,
				insured_addresses.STATE_CODE AS InsuredSubdivision ,
				insured_addresses.ZIP_CODE AS InsuredPostalCode ,
				insured_addresses.COUNTY AS InsuredCounty ,
				insured_addresses.COUNTRY_CODE AS InsuredCountry ,
				0 AS InsuredPublicIndicator ,
				insureds.NAICS_CODE AS InsuredNAICS ,
				insureds.SIC_CODE AS InsuredSIC ,
				NULL AS InsuredDandBNumber ,
				insured_contacts.WEB_SITE AS InsuredWebSite ,
				insured_contacts.E_MAIL AS InsuredEmail ,
        insured_contacts.PHONE_1 AS InsuredPhone ,
        insured_contacts.FAX AS InsuredFax ,
        insureds.FEIN AS FEIN ,
				NULL AS SurplusLinesName     ,
				NULL AS SurplusLinesAddressLine1 ,
				NULL AS SurplusLinesAddressLine2 ,
				NULL AS SurplusLinesAddressLine3 ,
				NULL AS SurplusLinesCity ,
				NULL AS SurplusLinesSubdivision ,
				NULL AS SurplusLinesPostalCode ,
				NULL AS SurplusLinesCounty ,
				NULL AS SurplusLinesCountry ,
				NULL AS SurplusLinesAgentName ,
				NULL AS SurplusLinesLicenseNumber ,
				NULL AS SurplusLinesNJTRX ,
				NULL AS SurplusLinesNHEMP ,
				prd.C_DRAGON_ID AS ProducerId ,
				CASE prd.C_DRAGON_ID
          WHEN '197' THEN '48640'
          WHEN '309' THEN '49640'
          WHEN '13987' THEN '47654'
          WHEN '15306' THEN '48700'
          WHEN '18893' THEN '49639'
          WHEN '20432' THEN '44830'
          WHEN '27231' THEN '48594'
          WHEN '27628' THEN '47049'
          WHEN '28032' THEN '49376'
          WHEN '28832' THEN '49457'
          END AS ProducerContactId ,
				pol.C_PRODUCT_SEG AS ProductSegment ,			
        SUBSTR(UNDERWRITER_NAME,1,INSTR(UNDERWRITER_NAME,' ',1) - 1) AS UnderwriterFirstName,
        SUBSTR(UNDERWRITER_NAME,INSTR(UNDERWRITER_NAME,' ',1) + 1,LENGTH(UNDERWRITER_NAME)) AS UnderwriterLastName,      
				pol.C_BRANCH_NAME AS Branch ,
				subs.C_BUSINESS_TYPE AS BusinessType ,
				NULL AS SpecialIndustryType ,
				NULL AS SpecialIndustryClass ,
				CAST((pol.ENTITY_REFERENCE || pol.GID) AS VARCHAR2(255)) AS TransactionId ,
				CASE 
          WHEN TRANSACTION_ACTION = 'convertQuote' AND RENEWAL_INDICATOR <> 'R' THEN 20 -- New Business
          WHEN TRANSACTION_ACTION = 'convertQuote' AND RENEWAL_INDICATOR = 'R' THEN 30 -- Renewal
          WHEN TRANSACTION_ACTION IN ('createPolicy','redoPolicy','redoPostBooking') THEN 20
          WHEN TRANSACTION_ACTION IN ('renewPolicy') THEN 30
          WHEN TRANSACTION_ACTION IN ('changeExpiration','changeEffectiveDate','changeNameAddress',
                                      'changeProducer','endorsePolicy','finalAudit','quoteEndorseConvert',
                                      'redoPolicyEndorsement','reverseEndorsement') THEN 40
          WHEN TRANSACTION_ACTION IN ('cancellation') THEN 55
          WHEN TRANSACTION_ACTION IN ('reinstatement','reinstatementAudit') THEN 60
          WHEN TRANSACTION_ACTION IN ('rewrite') THEN 70
        END AS TransactionType ,
				COALESCE(pol.TRANS_EFFECTIVE_DATE, TO_DATE('9999-12-31', 'yyyy-mm-dd')) AS TransactionEffectiveDate ,
				COALESCE(pol.TRANS_EFFECTIVE_DATE, TO_DATE('9999-12-31', 'yyyy-mm-dd')) AS TransactionProcessedDate ,
				COALESCE(pol.TRANS_EFFECTIVE_DATE, TO_DATE('9999-12-31', 'yyyy-mm-dd')) AS TransactionIssueDate ,
				CASE 
					WHEN pol.TRANSACTION_ACTION = 'cancellation' 
						THEN pol.TRANS_EFFECTIVE_DATE 
					ELSE NULL
					END AS TransactionCancellationDate ,
				CASE pol.TRANSACTION_ACTION
					WHEN 'cancellation' THEN pol.CANCEL_TYPE		
					ELSE NULL			
				END AS TransactionCancellationType ,
				'USD' AS GrossPremiumCurrency , -- Default to USD
				pol.TRANSACTION_PREMIUM AS GrossPremiumAmount ,
				CAST(polcov.COVERAGE_TYPE AS VARCHAR2(256)) AS coveragetype ,
        --CAST(''AS VARCHAR(255)) AS coveragetype ,
				'US' AS PremiumCountry ,
				insured_addresses.STATE_CODE AS PremiumSubdivision ,
				NULL AS PremiumPostalCode ,
				'USD' AS PremiumAllocationCurrency ,
        COALESCE(polcov.WRITTEN_PREMIUM, 0) AS PremiumAllocationAmount ,
				CASE 
					WHEN polcov.WRITTEN_PREMIUM IS NULL OR pol.COMM_FULL_TERM_PREM IS NULL THEN 0
					WHEN polcov.WRITTEN_PREMIUM = 0 THEN 0					
					ELSE ((pol.COMM_FULL_TERM_PREM/polcov.WRITTEN_PREMIUM) * 100) 
				END AS PrgmAdmCommissionPercentage ,
				COALESCE(pol.COMM_FULL_TERM_PREM, 0) AS PrgmAdmCommissionAmount ,
				pol.TOTAL_SURCHARGE AS PremiumAllocationSurcharges ,
				pol.TOTAL_FTERM_TAXES AS PremiumAllocationMiscTaxes ,
				NULL AS PremiumAllocationPolicyFees ,
				NULL AS PremiumAllocationMiscFees ,
				0 AS DefenseInside ,
				1 AS Occurrence ,
				polcov.LIMIT AS PerClaimLimit ,
				NULL AS AggregateLimit ,
				polcov.DEDUCTIBLE AS PerClaimDeductible ,
				NULL AS AggregateDeductible ,
        0 AS AssumedIndicator,
        NULL AS CedantCarrier,
        0 AS DeregulationIndicator ,
        CASE pol.COMPANY_CODE WHEN 'IC' THEN 0 ELSE 1 END AS AdmittedIndicator ,
        NULL AS AffiliatedPolicyEffectiveDate ,
        NULL AS AffiliatedPolicyExpirationDate ,
        nyftz.NYFTZ_CLASS_NUMBER AS NYFTZClass ,
        nyftz.NYFTZ_CLASS_CODE AS NYFTZStatCode 
		FROM MIC_POLICY_AW.RT_MIS_QUOTE_POLICIES pol     
			LEFT JOIN MIC_POLICY_AW.RT_MIS_INSUREDS insureds
				ON insureds.ENTITY_REFERENCE = pol.ENTITY_REFERENCE
			LEFT JOIN MIC_POLICY_AW.RT_MIS_ADDRESSES insured_addresses
				ON insured_addresses.FK_COLUMN_VALUE = insureds.GID
				AND insured_addresses.FK_COLUMN_NAME = 'INSURED_ADDRESS'
			LEFT JOIN MIC_POLICY_AW.RT_MIS_C_SUBMISSION subs
				ON subs.entity_reference = pol.submission_id
			LEFT JOIN MIC_POLICY_AW.RT_MIS_PRODUCERS prd
				ON prd.entity_reference = pol.ENTITY_REFERENCE
			LEFT JOIN MIC_POLICY_AW.RT_MIS_CONTACTS insured_contacts
				ON insured_contacts.FK_COLUMN_VALUE = insureds.GID
				AND insured_contacts.FK_COLUMN_NAME = 'INSURED'	
      LEFT JOIN MIC_POLICY_AW.RT_MIS_LX_NYFTZ nyftz ON pol.ENTITY_REFERENCE = nyftz.ENTITY_REFERENCE
      INNER JOIN polcov
        ON pol.ENTITY_REFERENCE = polcov.ENTITY_REFERENCE
      INNER JOIN MIC_POLICY_AW.MIS_POLICIES mispol ON  pol.ENTITY_REFERENCE = MPO_POLICY_REFERENCE
		WHERE 1 = 1
      AND pol.BOOKING_DATE IS NOT NULL
      AND pol.TRANSACTION_ACTION IN ('cancellation','changeExpiration','changeEffectiveDate','changeNameAddress'
                          ,'changeProducer','convertQuote','createPolicy','endorsePolicy','finalAudit'
                          ,'quoteEndorseConvert','redoPolicy','redoPostBooking','redoPolicyEndorsement'
                          ,'reinstatement','reinstatementAudit','renewPolicy','reverseEndorsement','rewrite')
/

