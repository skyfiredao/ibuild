ichange tools
======

#### itrack.sh
stand-alone tool, tracking gerrit stream-events and save it as json in allow host from conf

#### json2svn.sh
non-stand-alone tool, convert gerrit stream-events json file to svn:ichange by itrack.sh

#### sort_patch.sh
stand-alone tool, list 24 hours patch from svn:ichange

Usage: sort_patch.sh YYYYMMDD gerrit_server_doamin_name project/branch

#### conf/HOSTNAME.conf
config file for itrack: 

GERRIT_SRV_LIST=gerrit1 gerrit2

DOMAIN_NAME=your_domain.name

GERRIT_SRV_PORT=gerrit_port

GERRIT_ROBOT=login_account

GERRIT_XML_URL=manifest_path

GERRIT_BRANCH=branch_name

ICHANGE_SVN_SRV=svn:icahnge_URL

ICHANGE_SVN_OPTION=svn_option

