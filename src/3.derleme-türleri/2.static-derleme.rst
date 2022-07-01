Static derleme
^^^^^^^^^^^^^^
Static olarak derlenmiş bir dosya bağımlılığa sahip değildir. Initramfs gibi yerlerde kullanmak için uygundur. Bir kodu static olarak derlemek için **-static** parametresi kullanılır.
Bu parametre ihtiyaç duyulan kütüphanelerin derlenmiş olan dosyaya gömülmesini sağlar.

.. code-block:: shell

	$ gcc -o main main.c -static

Bir dosyanın static olup olmadığını anlamak için **ldd** komutunun hata mesajı vermesine bakılabilir. 

.. code-block:: shell

	$ ldd main
	    not a dynamic executable
