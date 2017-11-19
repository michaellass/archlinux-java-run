# Maintainer: Michael Lass <bevan@bi-co.net>
pkgname=archlinux-java-run
pkgver=2
pkgrel=1
pkgdesc="Java Application Launcher for Arch Linux"
arch=(any)
url="https://github.com/michaellass/archlinux-java-run"
license=('MIT')
depends=(bash java-runtime-common)
source=(archlinux-java-run.sh LICENSE README.md)
sha256sums=('9175f92d08a0e20d81047ac2f9403a6b063908aa7c79126d183d953162499206'
            '02784d4f0a945304e4b8cf0f91ae04010d18c3c1472ce470e394f9e86ed31b97'
            '1da3ca1b8c32910e7942d32b3eceb74f87404843dcc11e244ff723b4a0b3583a')

package() {
  install -Dm755 archlinux-java-run.sh "${pkgdir}"/usr/bin/archlinux-java-run
  install -Dm644 LICENSE "${pkgdir}"/usr/share/licenses/${pkgname}/LICENSE
  install -Dm644 README.md "${pkgdir}"/usr/share/doc/${pkgname}/README.md
}
