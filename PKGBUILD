# Maintainer: Michael Lass <bevan@bi-co.net>
pkgname=archlinux-java-run
pkgver=4
pkgrel=1
pkgdesc="Java Application Launcher for Arch Linux"
arch=(any)
url="https://github.com/michaellass/archlinux-java-run"
license=('MIT')
depends=(bash java-runtime-common)
source=(archlinux-java-run.sh LICENSE README.md)
sha256sums=('28369a1f4732c755c1fc150ea76fd89a20a2d2305f3bb1f8a32b5aefe7d3e850'
            '02784d4f0a945304e4b8cf0f91ae04010d18c3c1472ce470e394f9e86ed31b97'
            '1ea53d123d6113ff7779b8fe15daf55dbb16347a725b97dceaa0515db5bba7c7')

package() {
  install -Dm755 archlinux-java-run.sh "${pkgdir}"/usr/bin/archlinux-java-run
  install -Dm644 LICENSE "${pkgdir}"/usr/share/licenses/${pkgname}/LICENSE
  install -Dm644 README.md "${pkgdir}"/usr/share/doc/${pkgname}/README.md
}
