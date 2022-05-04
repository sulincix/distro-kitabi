Paket Yönetim Sistemi
=====================
Bu dokümanda paket yönetim sisteminin yapısı ve nasıl geliştirileceği anlatılmaktadır.
Bu dokümanda örnek olması açısından **python** ve **bash** programlama dilleri kullanılacaktır.
Eğer yeterli programlama yeteneğiniz olduğundan emin değilseniz dokümanı okumaya başlamadan önce programlama becerilerinizi gözden geçirebilirsiniz.

Bu dokümanda yer alan örnekler konuyu kavramanız için basitleştirilmeye çalışılmıştır. Yer alan örneklerde kullanılan yapıların benzerlerini yazarak kendi paket sisteminizi oluşturmanız hedeflenmektedir.

Dokümanda herhangi bir paket sistemi baz alınmamıştır. Tüm örnekler ve bu dokümanın kendisi **GPLv3** lisansı ile lisanslıdır.

Önsöz
-----
Türkler önsöz okumaz :D

Bölüm 1: Paket sistemi tanımı ve temel yapısı
---------------------------------------------

Paket sisteminin tanımı
^^^^^^^^^^^^^^^^^^^^^^^

Paket yönetim sistemleri bir dağıtımda bulunan en temel parçadır.
Sistem üzerine paket kurma ve kaldırma güncelleme yapma gibi işlemlerden sorumludur.
Başlıca 2 tip paket sistemi vardır:

* Binary (ikili) paket sistemi
* Source (kaynak) paket sistemi

Bir paket sistemi hem binary hem source paket sistemi özelliklerine sahip olabilir. Bununla birlikte son kullanıcı dağıtımlarında genellikle binary paket sistemleri tercih edilir.


Binary paket sistemi
++++++++++++++++++++
Bu tip paket sistemlerinde önceden derlenmiş olan paketler hazır şekilde indirilir ve açılarak sistem ile birleştirilir. 
Binary paket sistemlerinde paketler önceden derleme talimatları ile oluşturulmalıdır.

Binary paket sistemine örnek olarak **apt**, **dnf**, **pacman** örnek verilebilir.

Source paket sistemi
++++++++++++++++++++
Bu tip paket sistemlerinde derleme talimatları kurulum yapılacak bilgisayar üzerinde kullanılarak paketler kurulum yapılacak bilgisayarda oluşturulur ve kurulur.

Source paket sistemine örnek olarak **portage** örnek verilebilir.


Paket sisteminin temel yapısı
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Paket sistemleri 4 ana başlık altında incelenecektir:

* Komut satırı ve parametre işleme
* Paket kurulumu ve kaldırmaya yarayan işlemler
* Depo indexleme ve depo yönetimi
* Paket derleme

Komut satırı
++++++++++++
Komut satırı kullanıcıdan gelen isteği yerine getirmek için kullanılan söz dizisidir.
Paket sisteminde komut olarak **install**, **remove**, **update** bulunur.
Bu komutlar ilk parametredir ve sonrasonda paket isimleri veya ek parametreler bulunur. Örneğin:

.. code-block:: shell

	apt-get install --reinstall gimp

Yukarıdaki örnekte install yapılacak eylem --reinstall ek parametre gimp ise paket adıdır.

Paket kurma ve kaldırma
+++++++++++++++++++++++
Paket kurulurken paket içerisinde bulunan dosyalar sisteme kopyalanır.
Daha sonra istenirse silinebilmesi için paket içeriğinde dosyaların listesi tutulur.
Bu dosya ayrıca paketin bütünlüğünü kontrol etmek için de kullanılır.

Örneğin bir paketimiz zip dosyası olsun ve içinde dosya listesini tutan **.LIST** adında bir dosyamız olsun. Paketi aşağıdaki gibi kurabiliriz.

.. code-block:: shell

	cd /onbellek/dizini
	unzip /dosya/yolu/paket.zip
	cp -rfp ./* /
	cp .LIST /paket/veri/yolu/paket.LIST

Bu örnekte ilk satırda geçici dizine gittik ve paeti oraya açtık.
Daha sonra paket içeriğini kök dizine kopyaladık.
Daha sonra paket dosya listesini verilerin tutulduğu yere kopyaladık.
Bu işlemden sonra paket kurulmuş oldu.

Paketi kaldırmak için ise aşağıdaki örnek kullanılabilir.

.. code-block:: shell

	cat /paket/veri/yolu/paket.LIST | while read dosya ; do
	    if [[ -f "$dosya" ]] ; then
	        rm -f "$dosya"
	    fi
	done
	cat /paket/veri/yolu/paket.LIST | while read dizin ; do
	    if [[ -d "$dizin" ]] ; then
	        rmdir "$dizin" || true
	    fi
	done
	rm -f /paket/veri/yolu/paket.LIST

Bu örnekte paket listesini satır satır okuduk. Önce dosya olanları sildik.
Daha sonra tekrar okuyup boş kalan dizinleri sildik.
Son olarak palet listesi dosyamızı sildik.
Bu işlem sonunda paket silinmiş oldu.

Depo indexleme
++++++++++++++
Depo, paket yönetim sistemlerinde kurulacak olan paketleri içeren bir veri topluluğudur.
Kaynak depo ve ikili depo olarak ikiye ayrılır.
Depo içerisinde hiyerarşik olarak paketler yer alır.
Index ise depoda yer alan paketlerin isimleri sürüm numaraları gibi bilgiler ile adreslerini tutan kayıttır.
Paket yönetim sistemi index içerisinden gelen veriye göre gerekli paketi indirir ve kurar. Depo indexi aşağıdaki gibi olabilir:

.. code-block:: yaml

	Package: hello
	Version: 1.0
	Dependencies: test, foo, bar
	Path: h/hello/hello_1.0_x86_64.zip
	
	Package: test
	Version: 1.1
	Path: t/test/test_1.1_aarch64.zip
	
	...

Yukarıdaki örnekte paket adı bilgisi sürüm bilgisi ve bağımılılıklar gibi bilgiler ile paketin sunucu içerisindeki konumu yer almaktadır.
Depo indexi paketlerin içinde yer alan paket bilgileri okunarak otomatik olarak oluşturulur.

Örneğin paketlerimiz zip dosyası olsun ve paket bilgisini **.INFO** dosyası taşısın. Aşağıdaki gibi depo indexi alabiliriz.

.. code-block:: shell

	function index {
	    > index.txt
	    for i in $@ ; do
	        unzip -p $i .INFO >> index.txt
	        echo "Path: $i" >> index.txt
	    done
	}
	index t/test/test_1.0_x86_64.zip h/hello/hello_1.1_aarch64.zip ...

Bu örnekte paketlerin içindeki paket bilgisi içeren dosyaları uç uca ekledik.
Buna ek olarak paketin nerede olduğunu anlamak içn paket konumunu da ekledik.

Paket derleme
+++++++++++++
Paket sistemlerinde ikili paketler oluşturulurken derleme talimatı kullanılır.
Bu talimat paketin nasıl derleneceğini ve nereye hangi dosyanın geleceğini belirler.
Ayrıca paketin kaynak kodunun nerede olduğu gibi bilgileri de içerir.

.. code-block:: shell

	name="bash"
	version="5.0"
	depends=(ncurses readline)
	archive=(
	    https://ftp.gnu.org/gnu/bash/bash-5.0.tar.gz
	)
	
	build(){
	    tar -xf bash-5.0.tar.gz
	    cd bash-5.0
	    ./configure --prefix=/usr
	    make
	}
	install(){
	    make install DESTDIR=/paketleme/dizini
	}

Yukarıdaki örnek derleme talimatında **build** ve **install** adında iki adet fonsiyon kullanarak paketin nasıl derleneceğini belirttik.
**archive** listesi indirilir ve build ve ardından install çalıştırılır.
**DESTDIR** değerini ayarlayarak paketleme dizinine kurulum yaptırdık.
**--perfix=/usr** parametresi ise paketin /usr/local yerine /usr/ içerisine kurulması için kullanıldı.

Paketlerin nasıl derlendiği ile ilgili gerekli bilgiyi kaynak kodun kendisinden veya archlinux gibi diğer dağıtımların depolarından bakabilirsiniz.

Paket sistemi derleme işlemi yaparken root yekisi kullanmamalıdır.
Bunun en önemli sebebi ise paket derlenirken hatalı bir durum oluşursa derleme yapan sisteme müdahale edebilir ve paket bozuk oluşturulabilir.
Bu durumun önüne geçebilmek için **fakeroot** ve **unshare** komutlarından veya aynı işe yarayan yöntemlere başvurmanız gerekmektedir.

