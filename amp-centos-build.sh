#!/bin/sh
#
# Usage: amp-centos-build.sh <build-tag>
#
#  where  the build-tag format is YYMMDD where YY is last year digit, MM is month, and DD is day
#
# NOTE: build-tag is auto generated by date if not provided.
#
# These need to match with the definition in .spec file
#
echo off

TODAY=`date +%y%m%d`
RELBUILD="${TODAY}"
if [ -n "${1}" ]; then
	RELBUILD=${1}
fi

CENTOSNAMEPREFIX=amp_sw_centos_8.0
CENTOSSPECFILE=SPECS/kernel-emag.spec
CENTOSOPTIMIZESPECFILE=SPECS/kernel-emag-optimized.spec
RPMVERSION=`grep -e "^%define rpmversion" ${CENTOSSPECFILE} | cut -d' ' -f3`
PKGRELEASE=`grep -e "^%define pkgrelease" ${CENTOSSPECFILE} | cut -d' ' -f3`

rpmversion=${RPMVERSION}
pkgrelease=${PKGRELEASE}

# Prepare Linux source in SOURCES/
LINUX_SRC=linux-${rpmversion}-${pkgrelease}
rm -fr ${LINUX_SRC} SOURCES/linux-${rpmversion}-${pkgrelease}.tar.xz
cp -r ../amp-centos ${LINUX_SRC}
cd ${LINUX_SRC};make distclean;rm -fr .git;cd -
tar -cJf SOURCES/linux-${rpmversion}-${pkgrelease}.tar.xz ${LINUX_SRC}
rm -fr ${LINUX_SRC} RPMS/aarch64/* SRPMS/*

echo "Building for generic release tag ${RELBUILD}"

#Update build release tag to spec file
#sed -i "s/ buildid \..*/ buildid \.${RELBUILD}+amp/g" ${CENTOSSPECFILE}

rpmbuild --target aarch64 --define "%_topdir `pwd`" --define "buildid .${RELBUILD}+amp" --without debug --without debuginfo --without tools --without perf -ba ${CENTOSSPECFILE}

cd RPMS/aarch64; md5sum *.rpm > ${CENTOSNAMEPREFIX}-${RELBUILD}_md5sum.txt; cd -
cd RPMS/; tar -cJf ../${CENTOSNAMEPREFIX}-${RELBUILD}.tar.xz aarch64;cd -
tar -cJf ${CENTOSNAMEPREFIX}-${RELBUILD}.src.tar.xz SRPMS

rm -rf RPMS/aarch64/* SRPMS/*

echo "Building for optimized release tag ${RELBUILD}"

#Update build release tag to spec file
#sed -i "s/ buildid \..*/ buildid \.${RELBUILD}+amp.opt/g" ${CENTOSOPTIMIZESPECFILE}

rpmbuild --target aarch64 --define "%_topdir `pwd`" --define "buildid .${RELBUILD}+amp.opt" --without debug --without debuginfo --without tools --without perf -ba ${CENTOSOPTIMIZESPECFILE}

cd RPMS/aarch64; md5sum *.rpm > ${CENTOSNAMEPREFIX}-${RELBUILD}.opt_md5sum.txt; cd -
cd RPMS/; tar -cJf ../${CENTOSNAMEPREFIX}-${RELBUILD}.opt.tar.xz aarch64;cd -
tar -cJf ${CENTOSNAMEPREFIX}-${RELBUILD}.opt-src.tar.xz SRPMS
rm -fr RPMS/aarch64/* SRPMS/*
