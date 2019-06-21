
from emcli import *

#Set the OMS url to connect to 
set_client_property('EMCLI_OMS_URL','https://awnjpoda01-em.awacgbl.com:7802/em')
#Accept all the certificates
set_client_property('EMCLI_TRUSTALL','true')

inp_username=sys.argv[0]

#Login to the OMS

login(username=inp_username)

res = emcli.get_targets(targets="oracle_database")
print 'Number of targets:'+str(len(res.out()['data']))
print 'Errors           :'+res.error()
print 'Exit code        :'+str(res.exit_code())
print 'IsJson           :'+str(res.isJson())


