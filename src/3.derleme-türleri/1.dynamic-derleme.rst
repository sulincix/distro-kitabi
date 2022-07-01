Dynamic derleme
^^^^^^^^^^^^^^^
Dynamic olarak derlenen bir dosya düşük boyutludur ve bağımlılıkları bulunur. Derleme yapılırken ek parametre kullanılmaz.

.. code-block:: shell

	$ gcc -o main main.c

Dynamic derlenmiş bir dosyanın bağımlılıklarını **ldd** komutu kullanarak öğrenebiliriz. Eğer ldd komutu hata mesajı ile geri dönüş veriyorsa static olarak derlenmiş demektir.

.. code-block:: shell

	$ ldd /bin/bash
	    linux-vdso.so.1 (0x00007ffc8f136000)
	    libtinfo.so.6 => /lib/x86_64-linux-gnu/libtinfo.so.6 (0x00007ff10adcd000)
	    libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007ff10adc7000)
	    libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007ff10ac02000)
	    /lib64/ld-linux-x86-64.so.2 (0x00007ff10af6c000)

Burada **libc.so.6** ve **ld-linux-x86_64.so.2** dosyaları tamamında ortaktır ve **glibc** tarafından sağlanır. 
Dynamic derlenmiş bir dosyanın derlenmesi veya çalıştırılabilmesi için tüm bağımlılıklarının sistemde bulunması gereklidir.
