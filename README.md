# Kartaca Stajyer Sistem Yöneticisi Görevi

## İçerik

- **kartaca-wordpress.sls**: Salt state dosyası
- **kartaca-pillar.sls**: Salt pillar dosyası

## Kullanım

Salt Master sunucusunda veya uygun bir Salt Minion sunucuda aşağıdaki komutları kullanarak state dosyasını uygulayabilirsiniz:

```
$ salt "*" test.ping
```

Yukarıdaki komutla minion'ların bağlantısını test edebilirsiniz. Ardından, state dosyasını uygulamak için:

```
$ salt "*" state.sls kartaca-wordpress
```
