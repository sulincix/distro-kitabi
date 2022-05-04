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

Bölüm 2: Paket sisteminin iç yapısı
-----------------------------------
Paket yönetim sistemlerinde paket kurma ve kaldırma işlemleri aşağıdaki sıra ile yapılır:

* Yerel veritabanından paketlerin durununun sorgulanması
* Paket bağımılıklarının çözümlenmesi
* Paketlerin kurulabilirliğinin denetlenmesi
* Paketlerin indirlmesi
* Paketlerin bütünlüğünün kontrol edilmesi
* Paketlerin kurulması
* Paket kurulum sonrası işlemlerin yapılması
* Yerel veritabanının güncellenmesi

Paketlerin sorgulanması
^^^^^^^^^^^^^^^^^^^^^^^
Paket sistemleri paketler kurulmadan önce paketler kurulu mu değil mi diye kontrolden geçer.
Hangi paketlerin kurulacağıda dair bir liste oluşturulur.
Bu listede yer alan paketler bir sonraki aşamaya geçer.

.. code-block:: python

	need_install = []
	for pkg in pkg_list:
	    if not pkg.is_installed():
	        need_install.append(pkg.name)

Yukarıdaki örnekte paket kurulu değilse kurulacak paketler listesine eklenir.
Paket kaldırılırken de bu işlemin tam tersi plarak kurulu olmayan paketler es geçilir.

Paket bağımılıkları çözme
^^^^^^^^^^^^^^^^^^^^^^^^^
Bir paket sisteminin en karmaşık ve en önemli parçası bağımılık çözme kısmıdır.
Bu kısımda paketler ihtiyaç duyulan bağımlılıkları ile beraber kurulacağı için hangi paketlerin gerekli olduğuna karar veren kısım burasıdır.
Çalışma prensibi olarak sürekli kendini tekrarlayan bir fonksiyon bulunur ve bu fonksiyon tamamı hesaplanana kadar içi içe çalışmaya devam eder.

Bir pakete ihtiyaç duyan tüm paketlere ters bağımlılık adı verilir. Bu yapıyı ağacın köklerine ve dallarına benzetebiliriz. Bir dala ulaşmak için geçmemiz gereken dallar bağımlılıkları bir dalı kestiğimizde etkilenen dallar işe ters bağımlılıkları ifade eder.

.. code-block:: python

	need_install = []
	def resolve(package):
	    for pkg in package.dependencies:
	        if pkg not in need_install:
	            resolve(pkg)
	    if not package.is_installed():
	        need_install.append(package)
	resolve(xxxx)

Yukarıdaki örnekte bağımlılık ağacı bulma gösterilmiştir. Burada **resolve** fonksiyonu kendi kendisini iç içe çağırır.
Paketlerin bağımlılıkları ve onun alt bağımlılıkları bu fonksiyona sokulur. Kurulu olmayanlar kurulacak paket listesine eklenir.
Burada bazı durumlarda bu döngüsel işlem kısır döngüye girip sonsuz kere tekrar edebilir ve işlem bitmez.
Bu duruma **cycle dependency** adı verilir. Genellikle kötü paketlenmiş paketlerden kaynaklanır. Kaynak tabanlı paket sistemlerinde bu durum çözülemezken ikili paket sistemlerinde derleme yapılmayacağı için aşağıdaki gibi bir çözüm bulunabilir.

.. code-block:: python

	...
	if package in cache_list:
	    if package not in cycle_list:
	        cycle_list.append(package)
	    return
	cache_list.append(package)
	...

Yukarıdaki örnekte her paket sadece bir kez resove fonksiyonundan geçer.
Bu sayede cycle dependency sorunu aşılmış olur. Kaynak tabanlı paket sistemlerinde bu çözüm işe yaramayabilir.
Bunun sebebi ise paketler derlenirken kullanılacak derleme bağımlılığı sırası hatalı hesaplanabilir.
Bu sebeple paketçilerin cycle dependency sorununa sebep olmaması gereklidir.

Yukarıdaki örnekte eğer cycle dependency sorunu oluştuysa cycle_list listesinde bunların listesi tutulur.
Kaynak tabanlı paket listesinde bu listede bir eleman varsa derleme yapılamayacağı için hata verip çıkması sağlanmalıdır.

Bazı durumlarda bir paket kurulu iken başma bir paketin kurulamaması gerekmektedir.
Bu gibi durumlara **conflict** adı verilir. Conflict varsa kurulu olan paket silinir ve yerine istenen paket kurulur.
Veya bu işlemi kullanıcının elle yapması istenir ve hata mesajı verilerek kapanır.

.. code-block:: python

	...
	for pkg in package.conflicts:
	    if pkg.is_installed():
	        error_message("Conflict detected! Please remove %s" % pkg.name)
	    elif pkg in need_install:
	        error_message("Conflict detected! Cannot resolve %s" % pkg.name)
	...

Yukarıdaki örnekte paketin çakışmaları mevcutsa kurulum reddediliyor. Ayrıca paket bağımlılığı listesinde birbiri ile çakışan paketler mevcutsa da kurulum reddedilmelidir.

Ters bağımlılıklar hesaplanırken burada yapılan işlemin tam tersi yapılır.
Kaldırılacak olan paket diğer paketlerde ağımlılık olarak ekli mi diye bakılır ve aynı işlem onlara da uygulanır.
ters bağımlılıklarda da cycle dependency sorunu oluşabilir. Fakat kaynak tabanlılarda da kaldırma işleminde cycle dependency soruna sebep olmaz.

.. code-block:: python

	...
	need_remove = []
	def resolve_revdep(package):
	    if package not in need_remove:
	        need_remove.append(package)
	    for pkg in all_packages:
	        if package in pkg.dependencies:
	            resolve_revdep(pkg)
	resolve_revdep(xxx)
	...

Yukarıdaki örnekte paket hangi paketlere ait bağımlılık diye tespit edildi ve iç içe aynı işlemler uygulandı.

Paket kurulabilirliğinin denetlenmesi
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Paket sistemimiz kurulacak veya kaldırılacak paketlerin listesini oluşturduktan sonra bu paketlerin kullanılabilirliği denetlenmelidir. 
Eğer paket depoda yoksa veya hatalı sürümü varsa, paket kaldırıldığında sisteme zarar verecekse, paket kara listede ve kurulmaması gerekiyorsa engellenmesi gereklidir.


