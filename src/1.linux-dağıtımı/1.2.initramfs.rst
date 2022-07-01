initramfs
+++++++++
initramfs dosyası kernel ile birlikte kullanılan belleğe ilk yüklenen dosyadır. Bu dosyanın görevi sistemin kurulu olduğu diski tanımak için gereken modülleri yüklemek ve sistemi başlatmaktır. Bu dosya **/boot/initrd.img-xxx** konumunda yer alır.
initramfs dosyası üretmek için öncelikle bir dizin oluşturulur. Paketlenen dosya gzip veya lzma ile sıkmıştırılabilir veya sıkıştırılmadan da kullanılabilir.  Bu dizine gerekli dosyalar eklenir ve aşağıdaki gibi paketlenir.

.. code-block:: shell

	cd /initrd/dizini/
	find . | cpio -o -H newc | gzip -9 > /boot/initrd.img-xxx


Kernel initrd dosyasını ram üzerine yükler ve içerisindeki /init dosyasını çalıştırır.

Örneğin aşağıdaki gibi bir C dosyamız olsun.

.. code-block:: C

	#include <stdio.h>
	int main(){
	    printf("Hello World!\n");
	    while(1); // programın bitmesini engellemek için
	    return 0;
	}

Bu dosyayı static olarak derleyelim ve initramfs dosyasının içine koyup paketleyelim.

.. code-block:: shell

	mkdir /tmp/initrd
	cd /tmp/initrd
	gcc -o /home/deneme/main.c /tmp/initrd/init -static
	find . | cpio -o -H newc > /home/deneme/initrd.img

Daha sonra da qemu kullanarak test edelim.

.. code-block:: shell

	qemu-system-x86_86 --enable-kvm -kernel /boot/vmlinuz-5.17 -initrd /home/deneme/initrd.img -append "quiet" -m 512m

Eğer tüm adımları doğru yaptıysanız ekranda hello world yazısı ile karşılaşacaksınız. Ayrıca kendi işletim sisteminizi çalıştırmış olacaksınız.

Teorik olarak kernel ve initramfs tek başına bir işletim sistemi sayılabilir. Genel olarak linux dağıtımlarında sistemin kurulu olduğu diskte GNU sistemi bulunur ve kernel ve initramfs kullanılarak bu sistemdeki **/sbin/init** dosyası çalıştırılır. Bu dosya servis yöneticisi dosyamızdır ve sistemin geri kalanının çalışmasını sağlar. 

Yukarıdaki anlatımda initramfs nasıl çalıştığından söz edildi. Şimdi ise bir linux dağıtımında kullanılması için gereken işlemler üzerinde durulacaktır. Öncelikle initramfs oluşturma dizinimize gereken modülleri eklemeliniz. Bunun için /lib/modules/xxx içerisindeki dosyaları initramfs içine kopyalayalım. 

.. code-block:: shell

	...
	mkdir -p /tmp/initrd/lib/modules/
	for directory in {crypto,fs,lib} \
	    drivers/{block,ata,md,firewire} \
	    drivers/{scsi,message,pcmcia,virtio} \
	    drivers/usb/{host,storage}; do
	    find /lib/modules/$(uname -r)/kernel/${directory}/ -type f \
	        -exec install {} /tmp/initrd/lib/modules/$(uname -r)/ \;
	done
	depmod --all --basedir=/tmp/initrd
	...

Yukarıdaki örnekte ilk önce gerekli modülleri kopyaladık ve ardından modüllerin listesini güncellemek için **depmod** komutunu kullandık. Bu modülleri yüklemek için /init dosyamız içinde **modprobe** komutunu kullanabiliriz. Bu dosya genellikle **busybox ash** kullanılarak yazılır. Bunun için öncelikle busybox dosyamız initramfs dizinine kopyalanır. Ve ardından sembolik bağları atılarak komutları kullanılabilir hale getirilir.

.. code-block:: shell

	...
	mkdir -p /tmp/initrd/bin
	install /bin/busybox /tmp/initrd/busybox
	chroot /tmp/initrd /busybox --install -s /bin
	...

Burada eğer busybox static olarak derlenmemişse çalışmayacağı için **glibc** ve gereken diğer dosyalarımızı da eklememiz gerekmektedir. Bunun için önce **ldd** komutu ile bağımlılıkları öğrenilir ve bağımlılık dosyası initramfs dizininde /lib içine yerleştirilir. Bu işlem tüm alt bağımlılıklarda tekrarlarır. Aşağıdaki örnekte bağımlılıkların bulunması ve kopyalanması için bir fonksiyon oluşturulmuştur.

.. code-block:: shell

	...
	function get_lib(){
	    ldd $1 | cut -f3 -d" " | while read lib ; do
	        if [[ "$lib" == "" ]] ; then
	            : empty line
	        elif ! echo ${libs[@]} | grep $lib >/dev/null; then
	            echo $lib
	            get_lib $lib
	        fi
	    done | sort | uniq
	}
	function install_binary(){
	    get_lib $1 | while read lib ; do
	        file=/tmp/initrd/lib/$(basename $lib)
	        if [[ ! -f $file ]] ; then
	            install $lib $file
	        fi
	    done
	    install $1 /tmp/initrd/bin/$(basename $1)
	}
	mkdir -p /tmp/initrd/lib/
	ln -s lib /tmp/initrd/lib64
	install_binary /bin/busybox
	...

Eğer Bazı dağıtımlarda /lib64 bulunur. Bu sebeple lib64 adında bir sembolik bağ oluşturmamız gerekebilir. 

Modülleri yüklemek için elle **modprobe** komutu kullanılabilir. Bu sayede initramfs dosyamıza eklediğimiz modüllerin tamamını yükleyip donanımları tanıması sağlanabilir.

.. code-block:: shell

	...
	find /lib/modules/$(uname -r)/ -type f | while read module ; do
	    module_name=$(basename "$module"| sed "s/\..*//g")
	    if echo ${module_name} | grep "debug" ; then
	        : ignore debug module
	    else
	        modprobe ${module_name}
	    fi
	done
	...

Bu işlemin dezavantajı hem yavaş çalışması hem de gerekli olmayan modüllerin de yüklenmesidir. Bu yüzden bu yöntem yerine alternatif olarak **eudev** veya **systemd-udev** kullanılabilir. Bunun için initramfs dizinimize aşağıdaki eklemeler yapılır.

.. code-block:: shell

	...
	# eudev için
	install_binary /sbin/udevd
	# systemd-udev için
	install_binary /lib/systemd/systemd-udevd
	# Her ikisi için
	install_binary /sbin/udevadm
	...

Daha sonra initramfs içerisindeki /init içinde aşağıdaki komutlar çalıştırılmalıdır.

.. code-block:: shell

	...
	# systemd-udev için
	systemd-udevd --daemon
	# eudev için
	udevd --daemon
	# Her ikisi için
	udevadm trigger -c add
	udevadm settle
	...

Eğer systemd kullanmayan bir dağıtım geliştirecekseniz veya initramfs dosyasının daha az boyutlu olmasını istiyorsanız **eudev** tercih etmelisiniz.

Initramfs dosyasının birinci amacı ana sistemi diske bağlayıp görevi servis yöneticisine devretmektir. Bu sebeple önce disk bağlanır ve ardından içerisine **/dev**, **/sys**, **/proc** dizinleri bağlanır ve **switch_root** kullanılarak ana sisteme geçilir. 

.. code-block:: shell

	# Eğer yoksa dev sys proc dizinlerini oluşturalım.
	mkdir -p /dev /sys /proc
	# dev sys proc bağlayalım
	mount -t devtmpfs devtmpfs /dev
	mount -t sysfs sysfs /sys
	mount -t proc proc /proc
	...
	# diski bağlayalım
	mount $root /new_root
	# dev sys proc taşıyalım
	mount --move /dev /new_root/dev
	mount --move /sys /new_root/sys
	mount --move /proc /new_root/proc
	# /dev/root oluşturalım (isteğe bağlı)
	ln -s $root /new_root/dev/root
	# servis yöneticisini çalıştıralım.
	exec switch_root /new_root $init

Yukarıdaki örnekte **$root** ve **$init** değişkenleri değerini /proc/cmdline içerisinden okumalısınız. varsayılan init değeri **/sbin/init** olmalıdır.
