# Maintainer: Michael Lass <bevan@bi-co.net>
pkgname=archlinux-java-run
pkgver=1
pkgrel=1
pkgdesc="Java Application Launcher for Arch Linux"
arch=(any)
url="https://github.com/michaellass/archlinux-java-run"
license=('MIT')
depends=(bash java-runtime-common)
source=(archlinux-java-run.sh LICENSE README.md)
sha256sums=('371c12c8e3a3d9005e684a46466d0edf65b42060b084adbc65762afa4ab8f3c2'
            '02784d4f0a945304e4b8cf0f91ae04010d18c3c1472ce470e394f9e86ed31b97'
            '19790c41ecbec76f8c79f3e9d82581dcc9c127656628e336ad507a7080b8e8e7')

package() {
  install -Dm755 archlinux-java-run.sh "${pkgdir}"/usr/bin/archlinux-java-run
  install -Dm644 LICENSE "${pkgdir}"/usr/share/licenses/${pkgname}/LICENSE
  install -Dm644 README.md "${pkgdir}"/usr/share/doc/${pkgname}/README.md
}
