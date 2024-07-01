# Projektni zadadatak iz predmeta Ugrađani računarski sistemi

Tekst specifikacije projektnog zadatka se nalazi u repozitorijumu u fajlu *assignment.txt*.  
Proces rada i koraci koji su neophodnu za realizaciju traženog zadatka biće opisani u ovom tekstu.

# Preduslovi za izradu zadatka
1. BeagleBone AI 64 razvojna ploča sa napajanjem i eventualno kablom za povezivanje sa UART serijskim interfejsom na ploči
2. kabl sa mini DisplayPort konektorom na jednoj strani za povezivanje sa BB AI64
3. USB kamera ili CSI kamera (ako se koristi CSI kamera potrebno je imati i odgovarajući kabl sa 22-pinskim konektorom za povezivanje na BB AI64)
4. SD kartica

# Izrada zadatka
Na samom početku potrebno je odlučiti na koji način će se generisati *build* sistem za BB AI64 ploču, to podrazumijeva generisanje *toolchain-a*, *bootloader-a*, *kernel-a*, te *root* fajlsistema. U našemu slučaju za generisanje svih potrebnih komponenata izabran je *Buildroot* alat. 

## Generisanje sistema *Buildroot* alatom
Za početak potrebno je klonirati git repozitorijum *Buildroot* sistema sa njihove zvanične stranice, a zatim se prebaciti na granu 2024.05, jer u toj verziji postoje svi neophodni fajlovi za generisanje sistema za BB AI64 ploču. Potrebno je pozicionirati se u željeni direktorijum na računaru, a zatim izvršiti sljedeći skup komandi: 

```
git clone https://gitlab.com/buildroot.org/buildroot.git
cd buildroot
git checkout 2024.05
```
Također pošto *Buildroot* zahtijeva da na *host* sistemu postoje određeni softverski paketi, potrebno je provjeriti da li su svi [instalirani](https://buildroot.org/downloads/manual/manual.html#requirement-mandatory).

U ovoj verziji *Buildroot-a* postoji predefinisana konfiguracija koja uključuje neka osnovna podešavanje za ploču BB AI64. Ona se nalazi u folderu *configs* (kao niz drugih konfiguracija za neke druge razvojne ploče itd.) pod imenom *beagleboneai64_defconfig*.




