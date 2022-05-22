Linux dağıtımı kitabı
=====================
Bu dokümanda paket yönetim sisteminin yapısı ve nasıl geliştirileceği ve bağımsız tabanlı bir dağıtım tasarımı konuları anlatılmaktadır.
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
* Paketlerin indirilmesi
* Paketlerin bütünlüğünün kontrol edilmesi
* Paketlerin kurulması
* Paketlerin yapılandırılması
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

Paketlerin indirilmesi
^^^^^^^^^^^^^^^^^^^^^^
Paketlerin kurulabilirliği de denetlendikten sonra paketler indirilir.
Paketler indirilirken depo indexi içerisinden paketin nerede olduğu elde edilir ve o adrese istek atılır.
Paketler indirilme esnasında hata oluşursa işleme devam edilmez. Hata mesajı vererek çıkılmaşı gerekir.

.. code-block:: shell

	function fetcher {
	    paket_adi=$1
	    depo_adresi=$(get_repo $1)
	    paket_yolu=$(get_package_path $1)
	    wget -O /paket/onbellek/dizini/${paket_adi}.zip ${depo_adresi}/{paket_yolu}
	}
	fetcher hello

Yukarıdaki örnekte paket adı, konumu ve hangi depoda bulunduğu bilgisi alındıktan sonra paket önbelleğine indirilir.

Paketler indirilirken önce farklı bir dizine indirilip işlem bittiğinde önbelek dizinine taşınırsa paketler indirilirken oluşacak hatalar en aza indirilir.

Kaynak paketler için paketin derleme talimatı derlenmek üzere geçici dizine indirilir.
Derlemek için gereken arşiv dosyaları ve yamalar gibi diğer dosyalar derleme öncesi indirilmelidir. 
Bu işlem isterseniz derleme esnasında, isterseniz de kaynak paketler indirilirken gerçekleştirilir.

Eğer depo indexi eski ise indirme işleminde sorun oluşabilir. Bu durumun önüne geçebilmek için depo indexinin güncelliğini denetleyebiliriz. Bunu yapmanın en kolay yolu ise depo index dosyasının hash değerini tutan bir dosyayı indirip yereldeki örneği ile aynı mı diye bakmaktır. Bu sayede depoya güncelleme gelip gelmediğini tüm indexi indirmeye gerek kalmadan anlayabiliriz. Eğer depo indexi güncellendiyse paketleri indirmeden önce depo indexini güncelleyebiliriz. Bu işlem isteğe bağlıdır ve çoğu paket sistemi bunu kulanıcı insiyatifine bırakır.

Paket bütünlüğü kontrol etme
^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Paketler indirildikten sonra depo indexi içerisindeki hash değeri ile indirilen paketinki aynı mı diye bakılır.
Bununla birlikte gpg imzası kontrolü gibi ek kontroller yapılır. Bu sayede paketin gerçekten dağıtımın orijinal deposundan hatasız indirildiğinden emin olunur.

İkinci olarak paketlerin içerisindeki dosya listeleri çıkartılır ve çakışma var mı diye kontrol edilir.
Ayrıca başka bir paketin dosyası kurulu olan diğer paketin üzerine yazılmamalıdır.
Ancak paket bilgisinde üzerine yazılabilecek paket lisesi varsa ve paket o listedeyse bu durum görmezden gelinir.
Eğer dosya çakışması varsa buna **file confilct** adı verilir. Bu durum oluşuyorsa ve paket bilgisinde belirtilmemişse kurulum engellenmelidir.
File conflict kaynak paketlerde daha henüz derleme işlemine başlanmadığı için tespit edilemeyeceği için kontrol edilmez.

Dizinler için file confilct kontrolüne bakılmaz.

.. code-block:: python

	all_files = []
	for pkg in need_install:
	    for file is pkg.file_list:
	        if file in all_files:
	            error_message("File conflict detected %s" % file)
	        all_files.append(file)

Yukarıdaki örnekte bütün dosyaların yollarını tutan dizi oluşturulmuştur.
Bu diziye sırası ile kurulacak paketlerin dosyalarının yolları eklenmiştir.
Eğer dosya birden fazla pakette varsa filde conflict varlığı tespit edilip işleme son verilmiştir.

Paketlerin kurulması
^^^^^^^^^^^^^^^^^^^^
Paketler indirilip bütünlüğü de kontrol edildikten sonra paketlerin tek tek kurulması aşamasına geçilir.
Bu aşamada paketlerin arşivleri açılır ve paketteki dosyalar kök dizine kopyalanır.
Bazı dosyalar **config** dosyaları olduğu için mevcut olan dosyanın değiştirilmesi kullanıcının yaptığı ayarlamaları bozacağı için değiştirilmesi ya kullanıcıya sorulur yada değiştirilmez.

.. code-block:: python

	...
	for pkg in need_install:
	    for file in pkg.files:
	        if os.path.isfile(file):
	            if pkg.is_config(file):
	                continue
	        new_file = pkg.extract(file)
	        shutil.copyfile(new_file, file)
	...

Yukarıdaki örnekte paketin tüm dosyaları kök dizine kopyalandı. Fakat config dosyaları varsa e geçildi.
Paket geçici dizine çıkartıldı ve geçici konumdaki dosya aslı olması gereken konuma kopyalandı.

Paketlerdeki dosyalar root kullanıcısına ait olmalı ve dosya izninin 755 olması erekmektedir. Bunun haricinde dosya listesinde de dosya aitliği ve izinleri belirtilebilir.
Dosya listesi aşağıdaki gibi olabilir:

.. code-block:: yaml

	files:
	  - /bin/bash: 
	    - type: binary
	    - md5sum: 4883c32e5d4bed06efb4e669088a4a3a
	    - owner: root
	    - permission: 0755
	  - /etc/bashrc:
	    - type: config
	    - md5sum: d8f3f334e72c0e30032eae1a1229aef1
	    - owner: root
	    - permission: 0755
	...

Yukarıda yaml formatta örnek paket listesi verilmiştir. Paket sistemimiz bu listeyi okur ve buna göre dosyaları yerleştirir ve izinlerini ayarlar.
Ayrıca yukarıdaki örnekte paketteki dosyaların md5sum değeri de bulunmaktadır. Bu da paket geçici dizine açldıktan sonra kıyaslama amaçlı kullanılır ve paketin düzgün şekilde açıldığından emin olunduktan sonra dosya kök dizine koplalanır.

İkili paket sistemlerinda paketlerin kurulma sırasının önemi yoktur. Fakat kaynak tabanlı paket sistemlerinde bu durum biraz farklıdır. Paketler kurulmadan önce derleneceği için derlemede kullanılacak paketlerin daha önce derlenmesi gerekmektedir. Bu yüzden bağımlılık ağacı çözerken kullanılan sıranın tersinden başlanarak derleme yapılır. Örneğin aşağıdaki gibi 5 tane paket bulnsun:

.. code-block:: yaml

	paket-a:
	  ...
	  - deps: paket-b paket-c
	paket-b
	  ...
	  - deps: paket-c
	paket-c:
	  ...
	  -deps: 
	paket-d:
	  ...
	  - deps: paket-e
	paket-e:
	  ...
	  - deps:

Yukarıdaki örnektedi gibi bir bağımlılık ağacında derleme sırası: **e > c > d > b > a**  şeklinde olmalıdır. Bağımlılığı olmayan paketler en önce sonra ona ihtiyaç duyanlar şeklinde sıra izlenir. Burada cycle dependency sorunu bu sebeple derlemeyi çıkmaza sürükleyen önemli bir sorundur.

Kaynak tabanlı paket sistemlerinde paketler derlendikten sonra doğrudan kök dizine kurulmak yerine önce geçici dizine kurulup ardundan paket listesi çıkartılır ve daha sonra kök dizie kopyalanır. Bu sayede pakette hangi dosyaların bulunduğunn listesi tutulmuş olur.

Paketlerin yapılandırılması
^^^^^^^^^^^^^^^^^^^^^^^^^^^
Paket sistemi paketleri disk üzerine kurduktan sonra bazı komutların çalıştırılması gereklidir.
Örneğin sisteme yeni bir yazı tipi kurulduğunda yazı tipi önbelleği güncellenmelidir.
Bunun için ise **fc-cache -f** komutu kullanılır. Bu gibi senaryolarda paketlern içerisinde paket kurma ve kaldırmada gerekli komutlar bulunur.
Öneğin deb paketlerinde bu işlem **postinst**, **preinst**, **preinst**, **prerm** dosyaları ile gerçekleştirilir.
Bununla birlikte bu eylemler paketin içinde tutulmak yerine paket sistemine önceden tanımlanarak eklenebilir.

.. code-block:: shell

	...
	if [[ -f /var/lib/pkgsys/${pkgname}/post-install.sh ]] ; then
	    if ! /var/lib/pkgsys/${pkgname}/post-install.sh ; then
	        echo "Package ${pkgname} not configured yet!"
	        exit 1
	    if
	fi
	...

Yukarıdaki örnekte paketin kurulum sonrası eylemi varsa çalıştırıldı. Eğer çalıştırıken sorun meydana geldiyse hata mesajı verdi ve kapandı.
Paket sistemimiz prıgramı sonlandırmak yerine ayarlanamamış paketlerin listesini sonradan ayarlanabilmesi adına bir yerde tutabilir.

Diğer bir yol da önceden tanımlanan komutlardır. Bunun için bir dizinin veya dosyanın son değiçiklik tarihi ile yerel veritabanındaki farklı mı diye bakılabilir.
Örneğin /usr/share/fonts dizininin değişiklik tarihi değişmişse dizin içerisine dosya eklenmiş veya dosya silinmiştir. Bu durumda ilgili komut çalıştırılır.

.. code-block:: python

	...
	def post_operation(path, command):
	    if get_changes_time(path) > get_current_changes_time(path):
	        os.system(command)
	        set_current_changes_time(path, time.time())
	post_operation("/usr/share/fonts", "fc-cache -f")
	...

Yukarıdaki örnekte hedef dizinin değişiklik tarihi daha güncel ise komut çalıştırılır. 
Komut bittikten sonra dizinin değişikli tarihi şu anki tarih olarak güncellenir.
Bu sayede sadece değişiklik varsa komutun çalışması sağlanır.

Paket sonrası işlemlerin sırası paket bağımlılık ağacı sırası şeklinde olmalıdır. Kısaca ilk kurulan paket ilk yapılandırılır ilkesi gözetilir.

Yerel veri tabanının güncellenmesi
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Yerel veritabanı hangi paketlerin kurulu olduğunu ve hangi paketin hangi dosyaya sahip olduğu gibi bilgileri taşır.
Bunula birlikte depo indexini ve paketlerin yapılandırmalarını da kapsar.
Yerel veri tabanı herhangi bir işlem çalıştırılmadan önce okunur ve mevcut duruma göre işlem gerçekleştirilir.

Yerel veri tabanı güncelleme işleminin tamamı en son yapılmaz.
Bunu yerine paketlerle ilgili olan veriler (kurulu paket listesi, paket dosya listesi vb.) her paket kurulduğunda güncellenir.
Bu sayede işlem yarıda kesilirse veya sistemde ani olarak güç kaybı gerçekleşirse sistemin nerede kaldığı belli olur ve kurtarmak mümkün olur.
Bununla birlikte eğer index güncelleme işlemi yapılırsa yerel veri tabanı yeni indirilen indexi kullanmak için indirme sonunda da güncellenir.

Bölüm 3: Paket dosyası formatı
------------------------------
Paket sistemleri belirli bir paket formatını kullanır. Örneğin **deb**, **rpm**, **apk** gibi formatlar bulunur. Bu bölümde örnek bir paket formatı üzerinden paket formatının iç yapısını anlatılacaktır.

Paket dosyaları özünde birer arşiv dosyasıdır ve belli bir hiyerarşiye göre dizilir. 3 temel parçadan oluşur:

* Manifest dosyası
* Dosya listesi
* Dosya arşivi

Manifest dosyası
^^^^^^^^^^^^^^^^
Paketlerin manifest dosyalar paketin ne olduğunu, nelere bağımlı olduğunu, nelerle çakıştığı gibi bilgileri içeren paketin kimlik kartı niteliğinde olan dosyasıdır.
Bu dosya yaml, json, xml gibi formatlarda bulunur. 

.. code-block:: yaml

	- package:
	  - name: bash
	  - version: 5.0
	  - archive-hash: d1a9a848bcd295183cbec5ee500b406f
	  - dependencies: ncurses readline
	  - conflicts: bash-unstable
	  - architecture: x86_64
	  - description : GNU bash shell
	  - component: sys-app/core

Yukarıdaki örnekte manifest yaml formatında verilmiştir. Paketin adı sürümü gibi bilgilerin yanında arşivin md5sum değeri de yer almaktadır.
Bu değer paket açılmadan önceki bütünlük kontrolü için kullanılır. Eğer tutarlı değilse arşiv bozuk olarak indirilmiştir.
componont olarak gösterilen değer sistemin hangi parçasına ait olduğunu ayırt etmek için eklenen bir parametredir. 
Buna ek olarak isteğer bağlı farklı ek değerler eklenebilir.

Mainfest dosyası index oluşturulurken arşivden çıkartılır ve uc uca eklenerek index üretilir. Bu sebeple paket içerisinde genellikle sıkıştırılmamış halde bulunur.

Dosya listesi
^^^^^^^^^^^^^
Paketlerin dosya listeleri her dosyanın hash değerini kime ait olduğunu ve nerede yer aldığını belirten listedir.
Bu dosya manifest ile birleşik olarak tek dosya halinde de olabilir fakat bu index alırken boyutu ciddi ölçüde arttıracağı için genellikle tercih edilmez. 

Paket listelerinde dosya aitliği ve izni belirtilmek zorunda değildir. Temel olarak tüm dosyalar roota ait ve izin numarası 755 kabul ediliebilir ve paket kurulumu sonrası işlem olarak gerekli izinler değiştirilebilir.

.. code-block:: yaml

	d1a9a848bcd295183cbec5ee500b406f  /bin/bash
	d8f3f334e72c0e30032eae1a1229aef1  /etc/bashrc
	...

Yukarıdaki örnekte paket listesinde sadece md5sum değerleri ve dosya konumu yer almaktadır. Bu tür listelerde dosya aitliği e izni gibi değerler yer almaz.
Paket yapılandırma aşamasındayken izinler ayarlanabilir.

Paket arşivi
^^^^^^^^^^^^
Bu dosya paketimizin tüm dosyalarını içeren dosyadır. Bu dosya genellikle paketin boyutunu küçültmek amacı ile sıkıştırılmıştır.

Paket arşivi ve paket listesi metapaket adı verilen sadece bağımılık belirten paketlerde bulunmak zorunda değildir. Bu gibi paketlerin sadece manifesti bulunur ve paket sadece bağımlılıkları yardımı ile diğerlerinin de kurulmasını sağlar. Buna en iyi örnek masaüstü metapaketleridir.

Ek dosyalar
^^^^^^^^^^^
Paketin içerisinde ek olarak yapılandırma aşamasıda kullanılan dosyalar paketin simgesi paketin derleme talimatı gibi dosyalar yer alabilir.
Bu dosyalar paket sistemi tarafından farklı amaçlar için kullanılabilir veya herhangi bir işlevi olmayan dosyalar da olabilirler. 

Bölüm 4: Linux dağıtımının temel yapısı ve paket sistemi ile ilişkisi
---------------------------------------------------------------------
Bir linux dağıtımını oluşturan tüm parçalar paketlerden oluşur. Bu bölüm linux dağıtımının temel yapısı ve paket sistemi ile ilişkisi anlatılacaktır.

Linux dağıtımının temel yapısı
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Sıradan bir linux dağıtımını 4 temel parçada ele alabiliriz.

* kernel (linux)
* initramfs
* servis yöneticisi
* masaüstü ortamı

Kernel
++++++
Kernel sistemin en temel parçasıdır. Donanım ile iletişimi kurar ve sistemin işlevlerinin düzgün yerine getirilmesini sağlar. GNU/Linux dediğimizde GNU sistemi ve Linux çekirdeği kullanılmıx anlamına gelir. Çekirdek tek başına işletim sistemi değildir. Kernel aşağıdaki dizinlerde bulunur.

.. code-block:: shell

	/boot/vmlinuz-xxx
	/lib/modules/xxx
	/usr/src/linux-xxx

Burada xxx ile belirtilen kernelin sürümüdür. Bir sistemde birden çok kernel bulunabilir ve sistem açılırkein hangisi ile çalışacağı seçilebilir.

Linux derlemek için öncelikle **make menuconfig** komutu kullanılarak kernel yapılandırılır. Veya **make defconfig** kulanılarak varsayılan ayarlarda yapılandırılabilir.
Ardından vmlinuz dosyamızı derlemek için **make bzImage** kullanılır. Bu işlemden sonra kernelin ana dosyası oluşturulmuş olur. Kernel modüler yapıya sahiptir ve modüller sayesinde çalışma sırasında sürücüler açılıp kapatılabilir. Bu sayede kaynaktan tasarruf edilmiş olur. Modülleri derlemek için **make modules** kullanılır. Aşağıda özet olarak kernel derleme örneği yer almaktadır.

.. code-block:: shell

	make menuconfig
	make bzImage -j24
	make modules -j24

Derleme yaparken birden çok işlemci çekirdeğini kullanmak için **-j4** eklenebilir. burdada 4 işlem sayısıdır ve işlemci çekirdeği sayısı kadar olması önerilir. 

kernel yapılandırma dosyası kaynak kodun içerisinde **.config** dosyası olarak bulunur. Bu dosyayı yapılandırmak yerine hazır olarak ekleyerek kullanabilirsiniz.

Derlenmiş olan kernelimizi sisteme yüklemek için önce vmlinuz dosyamızı kopyalamamız gereklidir. vmlinuz dosyamız arch/x86/boot içinde yer alır. Daha sonra **make modules_install** kullanılarak modüller yüklenir. En son olarak kernelin kaynak kodunun bir kopyasını /usr/src içine kopyalamamız gereklidir. Bunun sebebi ise daha sonradan kurulması gereken herhangi bir sürücü oluştuğunda kernelin kaynak kodundan yararlanılmasıdır. Kernelimizin libc header dosyalarını yüklemek için **make headers_install** kullanılır. 

.. code-block:: shell

	install arch/x86/boot/bzImage $DESTDIR/boot/vmlinuz-5.17
	make modules_install INSTALL_MOD_PATH=$DESTDIR
	make headers_install INSTALL_HDR_PATH=$DESTDIR/usr
	cp -rf linux-5.17-source $DESTDIR/usr/src/linux-headers-5.17

Kernelin derlenmesi ve kurulması ile ilgili dağıtımdan dağıtıma farklılıklar bulunabilir. Sistemin çalışması için modüller ve vmlinuz dosyası gereklidir. Diğer dosyalar ise modül ve uygulama derlemek için kullanılır.

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

	# systemd-udev için
	systemd-udevd --daemon
	# eudev için
	udevd --daemon
	# Her ikisi için
	udevadm trigger -c add
	udevadm settle

Eğer systemd kullanmayan bir dağıtım geliştirecekseniz veya initramfs dosyasının daha az boyutlu olmasını istiyorsanız **eudev** tercih etmelisiniz.


