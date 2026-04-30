# frankenphp segfault showcase

The **alpine Docker image** seems to have problems with high amounts of environment variables (starting at around 400) which results in segfaults and silent crashes.

The **debian Docker image** does not have this problem.

Building the images on apple silicon locally does not result in any issues, only when building them for `--platform=linux/amd64`, which is the platform used in K8S.

The names and contents of the environment variables did not seem to have an impact on the behaviour; just the amount of environment variables made a difference.

## Reproduce

Commenting variables at the end of [env-file-segfault.txt](env-file-segfault.txt) upwards, sequentially, results in a "random" distribution of outcomes; alternating between segfaults, silent quits, or running fine.

```shell
composer setup
```

Alpine Build:

```shell
docker build -t segfault-showcase-alpine:local . --file=docker-alpine.Dockerfile --platform=linux/amd64
docker run -p 8888:8000 --rm --name=segfault-showcase-alpine --env-file=env-file-segfault.txt segfault-showcase-alpine:local
```

Results in:

```shell
   Symfony\Component\Process\Exception\ProcessSignaledException

  The process has been signaled with signal "11".

  at vendor/symfony/process/Process.php:488
    484▕             usleep(1000);
    485▕         }
    486▕
    487▕         if ($this->processInformation['signaled'] && $this->processInformation['termsig'] !== $this->latestSignal) {
  ➜ 488▕             throw new ProcessSignaledException($this);
    489▕         }
    490▕
    491▕         return $this->exitcode;
    492▕     }

      +17 vendor frames

  18  artisan:16
      Illuminate\Foundation\Application::handleCommand(Object(Symfony\Component\Console\Input\ArgvInput)
```

Debian Build:

```shell
docker build -t segfault-showcase-debian:local . --file=docker-debian.Dockerfile --platform=linux/amd64
docker run -p 8888:8000 --rm --name=segfault-showcase-debian --env-file=env-file-segfault.txt segfault-showcase-debian:local
```

Works fine.

Diffing the `phpinfo` outputs for both builds:

```shell
docker build -t segfault-showcase-phpinfo-alpine:local . --file=docker-phpinfo-alpine.Dockerfile --platform=linux/amd64
docker run -p 8888:8000 --rm --name=segfault-showcase-phpinfo-alpine --env-file=env-file-segfault.txt segfault-showcase-phpinfo-alpine:local > phpinfo-alpine.txt

docker build -t segfault-showcase-phpinfo-debian:local . --file=docker-phpinfo-debian.Dockerfile --platform=linux/amd64
docker run -p 8888:8000 --rm --name=segfault-showcase-phpinfo-debian --env-file=env-file-segfault.txt segfault-showcase-phpinfo-debian:local > phpinfo-debian.txt

diff phpinfo-alpine.txt phpinfo-debian.txt
```

Output:

```shell
< System => Linux 618020c5e4f9 6.19.13-orbstack-gbd1dc07b8cf4 #1 SMP PREEMPT Mon Apr 20 11:17:03 UTC 2026 x86_64
< Build Date => Apr 15 2026 20:19:28
---
> System => Linux 91ad773ee7c0 6.19.13-orbstack-gbd1dc07b8cf4 #1 SMP PREEMPT Mon Apr 20 11:17:03 UTC 2026 x86_64
> Build Date => Apr 22 2026 01:27:13
8c8
< Configure Command =>  './configure'  '--build=x86_64-linux-musl' '--sysconfdir=/usr/local/etc' '--with-config-file-path=/usr/local/etc/php' '--with-config-file-scan-dir=/usr/local/etc/php/conf.d' '--enable-option-checking=fatal' '--with-mhash' '--with-pic' '--enable-mbstring' '--enable-mysqlnd' '--with-password-argon2' '--with-sodium=shared' '--with-pdo-sqlite=/usr' '--with-sqlite3=/usr' '--with-curl' '--with-iconv=/usr' '--with-openssl' '--with-readline' '--with-zlib' '--enable-phpdbg' '--enable-phpdbg-readline' '--with-pear' '--enable-embed' '--enable-zts' '--disable-zend-signals' 'build_alias=x86_64-linux-musl' 'PHP_UNAME=Linux - Docker' 'PHP_BUILD_PROVIDER=https://github.com/docker-library/php'
---
> Configure Command =>  './configure'  '--build=x86_64-linux-gnu' '--sysconfdir=/usr/local/etc' '--with-config-file-path=/usr/local/etc/php' '--with-config-file-scan-dir=/usr/local/etc/php/conf.d' '--enable-option-checking=fatal' '--with-mhash' '--with-pic' '--enable-mbstring' '--enable-mysqlnd' '--with-password-argon2' '--with-sodium=shared' '--with-pdo-sqlite=/usr' '--with-sqlite3=/usr' '--with-curl' '--with-iconv' '--with-openssl' '--with-readline' '--with-zlib' '--enable-phpdbg' '--enable-phpdbg-readline' '--with-pear' '--with-libdir=lib/x86_64-linux-gnu' '--enable-embed' '--enable-zts' '--disable-zend-signals' 'build_alias=x86_64-linux-gnu' 'PHP_UNAME=Linux - Docker' 'PHP_BUILD_PROVIDER=https://github.com/docker-library/php'
155c155
< cURL Information => 8.17.0
---
> cURL Information => 8.14.1
169c169
< SPNEGO => No
---
> SPNEGO => Yes
174,175c174,175
< GSSAPI => No
< KERBEROS5 => No
---
> GSSAPI => Yes
> KERBEROS5 => Yes
187,190c187,191
< Protocols => dict, file, ftp, ftps, gopher, gophers, http, https, imap, imaps, mqtt, pop3, pop3s, rtsp, smb, smbs, smtp, smtps, telnet, tftp, ws, wss
< Host => x86_64-alpine-linux-musl
< SSL Version => OpenSSL/3.5.6
< ZLib Version => 1.3.2
---
> Protocols => dict, file, ftp, ftps, gopher, gophers, http, https, imap, imaps, ldap, ldaps, mqtt, pop3, pop3s, rtmp, rtmpe, rtmps, rtmpt, rtmpte, rtmpts, rtsp, scp, sftp, smb, smbs, smtp, smtps, telnet, tftp, ws, wss
> Host => x86_64-pc-linux-gnu
> SSL Version => OpenSSL/3.5.5
> ZLib Version => 1.3.1
> libSSH Version => libssh2/1.11.1
214c215
< libxml Version => 2.13.9
---
> libxml Version => 2.9.14
245,246c246,247
< iconv implementation => libiconv
< iconv library version => 1.18
---
> iconv implementation => glibc
> iconv library version => 2.41
260,261c261,262
< libXML Compiled Version => 2.13.9
< libXML Loaded Version => 21309
---
> libXML Compiled Version => 2.9.14
> libXML Loaded Version => 20914
274c275
< Multibyte regex (oniguruma) version => 6.9.10
---
> Multibyte regex (oniguruma) version => 6.9.9
308,310c309,311
< OpenSSL Library Version => OpenSSL 3.5.6 7 Apr 2026
< OpenSSL Header Version => OpenSSL 3.5.6 7 Apr 2026
< Openssl default config => /etc/ssl/openssl.cnf
---
> OpenSSL Library Version => OpenSSL 3.5.5 27 Jan 2026
> OpenSSL Header Version => OpenSSL 3.5.5 27 Jan 2026
> Openssl default config => /usr/lib/ssl/openssl.cnf
341c342
< SQLite Library => 3.51.2
---
> SQLite Library => 3.46.1
374c375
< Readline library => 8.3
---
> Readline library => 8.2
430,431c431,432
< libsodium headers version => 1.0.20
< libsodium library version => 1.0.20
---
> libsodium headers version => 1.0.18
> libsodium library version => 1.0.18
442c443
< SQLite Library => 3.51.2
---
> SQLite Library => 3.46.1
477c478
< libxml2 Version => 2.13.9
---
> libxml2 Version => 2.9.14
556,557c557,558
< Compiled Version => 1.3.2
< Linked Version => 1.3.2
---
> Compiled Version => 1.3.1
> Linked Version => 1.3.1
577c578
< HOSTNAME => 618020c5e4f9
---
> HOSTNAME => 91ad773ee7c0
581d581
< SHLVL => 1
1040c1040
< PHPIZE_DEPS => autoconf     dpkg-dev dpkg     file    g++     gcc     libc-dev    make    pkgconf     re2c
---
> PHPIZE_DEPS => autoconf     dpkg-dev    file    g++     gcc     libc-dev    make    pkg-config    re2c
1066c1066
< $_SERVER['HOSTNAME'] => 618020c5e4f9
---
> $_SERVER['HOSTNAME'] => 91ad773ee7c0
1070d1069
< $_SERVER['SHLVL'] => 1
1529c1528
< $_SERVER['PHPIZE_DEPS'] => autoconf     dpkg-dev dpkg     file    g++     gcc     libc-dev    make    pkgconf     re2c
---
> $_SERVER['PHPIZE_DEPS'] => autoconf     dpkg-dev    file    g++     gcc     libc-dev    make    pkg-config    re2c
1550,1551c1549,1550
< $_SERVER['REQUEST_TIME_FLOAT'] => 1777538973.8152
< $_SERVER['REQUEST_TIME'] => 1777538973
---
> $_SERVER['REQUEST_TIME_FLOAT'] => 1777538986.9724
> $_SERVER['REQUEST_TIME'] => 1777538986
1563c1562
< $_ENV['HOSTNAME'] => 618020c5e4f9
---
> $_ENV['HOSTNAME'] => 91ad773ee7c0
1567d1565
< $_ENV['SHLVL'] => 1
2026c2024
< $_ENV['PHPIZE_DEPS'] => autoconf    dpkg-dev dpkg     file    g++     gcc     libc-dev    make    pkgconf     re2c
---
> $_ENV['PHPIZE_DEPS'] => autoconf    dpkg-dev    file    g++     gcc     libc-dev    make    pkg-config    re2c
```

## Reproduction setup (this repository)

```shell
laravel new segfault-showcase && cd segfault-showcase
composer require laravel/octane
php artisan octane:install # just for the .gitignore update, the installed frankenphp binary is not used in containers
# Added env-file-segfault.txt
# Added *.Dockerfile
```
