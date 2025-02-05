# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/alexbarton.asc
inherit verify-sig

DESCRIPTION="An IRC server written from scratch"
HOMEPAGE="https://ngircd.barton.de/"
SRC_URI="https://arthur.barton.de/pub/${PN}/${P}.tar.gz"
SRC_URI+=" verify-sig? ( https://arthur.barton.de/pub/${PN}/${P}.tar.gz.sig )"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~arm arm64 x86 ~x64-macos"
IUSE="debug gnutls ident irc-plus +ipv6 libressl pam +ssl strict-rfc tcpd test zlib"

# Flaky test needs investigation (bug 719256)
RESTRICT="test"

RDEPEND="
	acct-user/ngircd
	acct-group/ngircd
	irc-plus? ( virtual/libiconv )
	ident? ( net-libs/libident )
	pam? ( sys-libs/pam )
	ssl? (
		gnutls? ( net-libs/gnutls:= )
		!gnutls? (
			!libressl? ( dev-libs/openssl:0= )
			libressl? ( dev-libs/libressl:0= )
		)
	)
	tcpd? ( sys-apps/tcp-wrappers )
	zlib? ( sys-libs/zlib )
"
DEPEND="${RDEPEND}"
BDEPEND="
	sys-devel/automake:1.11
	test? (
		dev-tcltk/expect
		net-misc/netkit-telnetd
	)
"

src_prepare() {
	default

	if ! use prefix ; then
		sed -i \
			-e "s:;ServerUID = 65534:ServerUID = ngircd:" \
			-e "s:;ServerGID = 65534:ServerGID = ngircd:" \
			doc/sample-ngircd.conf.tmpl || die
	fi

	# Note that if we need to use automake, we need a certain version (for now):
	# https://github.com/ngircd/ngircd/issues/261
	# eautomake
}

src_configure() {
	local myeconf=(
		--sysconfdir="${EPREFIX}"/etc/${PN}
		$(use_enable debug sniffer)
		$(use_enable debug)
		$(use_enable irc-plus ircplus)
		$(use_enable ipv6)
		$(use_enable strict-rfc)
		$(use_with irc-plus iconv)
		$(use_with ident)
		$(use_with pam)
		$(use_with tcpd tcp-wrappers)
		$(use_with zlib)
	)

	if use ssl ; then
		if use gnutls ; then
			myconf+=(
				$( use_with gnutls )
			)
		else
			myconf+=(
				$( use_with !gnutls openssl )
			)
		fi
	fi

	econf "${myeconf[@]}"
}

src_install() {
	default

	newinitd "${FILESDIR}"/ngircd.init-r1.d ngircd
}

pkg_postinst() {
	if [[ -z ${REPLACING_VERSIONS} ]] && use pam ; then
		elog "ngircd will use PAMIsOptionalPAM by default, please change this option."
		elog "You may not be able to login until you change this."
	fi
}
