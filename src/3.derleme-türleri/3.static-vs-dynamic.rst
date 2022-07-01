Static ve Dynamic derlemenin kıyaslanması
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Static olarak derlenmiş bir dosya sistemden bağımsız olarak çalışabilir. Örneğin elimizde aşağıdaki gibi bir kod olsun.

.. code-block:: C

	//main.c dosyası
	#include <stdio.h>
	int main(){
	    printf("Hello world\n");
	}

Bu kodu static ve dynamic olarak 2 farklı şekilde derleyip chroot içine atıp çalıştırmayı deneyelim.

.. code-block:: shell

	$ mkdir chroot
	$ gcc -o chroot/main main.c
	$ chroot chroot /main
	    chroot: failed to run command ‘/main’: No such file or directory
	$ gcc -o chroot/main main.c -static
	$ chroot chroot /main
	    Hello world

Gördüğünüz gibi dynamic olarak derlenmiş dosya libc bulamadığı için çalışmadı. Fakat static olarak derlenmiş dosyamız çalıştı.
Bununla birlikte dosya boyutlarını aşağıdaki gibi kıyaslayabiliriz.

.. code-block:: shell

	$ gcc -o main.dynamic main.c
	$ gcc -o main.static main.c -static
	$ du main*
	    4     main.c
	    20    main.dynamic
	    768   main.static

Gördüğünüz gibi dynamic olarak derlenmiş dosya boyut olarak çok daha küçüktür. Bu yüzden sistem içerisinde genellikle dynamic derlemeler tercih edilirken. initramfs gibi yerlerde static derleme tercih edilir.
