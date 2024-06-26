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
Također pošto *Buildroot* zahtijeva da na *host* sistemu postoje određeni softverski paketi, potrebno je provjeriti da li su svi [instalirani](https://buildroot.org/downloads/manual/manual.html#requirement-mandatory). Također prije instalacije neophodnih paketa (ukoliko neki od njih već nisu instlirani), preporuka je da se izvrši ažuriranje softverskih paketa u sistemu:

```
sudo apt update
sudo apt dist-upgrade
```

U ovoj verziji *Buildroot-a* postoji predefinisana konfiguracija koja uključuje neka osnovna podešavanje za ploču BB AI64. Ona se nalazi u folderu *configs* (kao niz drugih konfiguracija za neke druge razvojne ploče itd.) pod imenom *beagleboneai64_defconfig*.  
Učitaćemo ovu konfiguraciju kao polaznu, i nad njom izvršiti određene izmjene koje smo identifikovali kao potrebne za izradu zadatka.

```
make beagleboneai64_defconfig
```
, a zatim pokrenuti i konfiguracioni meni: 

```
make menuconfig
ili
make xconfig - ukoliko je instaliran softverski paket Qt5 na razvojnoj platformi 
```

Sada nam se otvara grafički interfejs u kojem možemo napraviti izmjene u konfiguracij koje ćemo primjeniti na ploču. 

- U okviru **Toochain** sekcije:
  - postavite **Toolchain type** opciju na **Buildroot toolchain** - jer želimo da nam *Buildroot* generiše *toolchain*
   - **custom toolchain vendor name** na urs ili neki drugi proizvoljan string
   - **C library** ostavljamo na **glibc**
   - **Kernel headers** na **Same as kernel being built**
   - **Custom kernel headers series** na **6.6.x** , jer ćemo izabrati kernel 6.6.30
   - **Binutils version** na **2.41** kao što je i podrazumijevano
   - **GCC compiler version** na **gcc 13.x** kao što i jeste

     > Izborom opcija iznad smo odlučili da nam *Buildroot* sistem izgradi *toolchain* uz ostavljanje nekih osnovnih opcija na proizvoljno podešavanje, prije svega izbor *glibc* biblioteke pri izgradnji *toolchain*, te verzija *kernel* zaglavlja na neke preporučene vrijednosti

   - pod **Aditional gcc options** podsekcijom ćemo uključiti opciju: **Enable C++ support**.
     
      > Ova opcija nam je neophodna, između ostalog, da bismo kasnije mogli izabrati opciju **libv4l** koja nam služi za rad sa *videoforlinux* uređajima među kojima će biti i naša kamera
     
- U okviru **Build options** sekcije:
  - možemo provjeriti **Location to save buildroot config** da vidimo gdje će biti sačuvana ova izmjenje konfiguracija. Ukoliko ostavimo podrazumijevanu putanju, izmjenjena konfiguracija će pregaziti postojeću.
- U okviru **System configuration** sekcije:
    - **System hostname** možemo podesiti na **urs**
    - **System banner** na **Welcome to URS**
    - **Init system** ćemo postaviti na **systemd**

      > Bitno je da izaberemo *system* kao inicijalizacioni sistem, jer ćemo na taj način moći iskorisiti skrite za inicijalizaciju koje se nalaze u folderu ploče, ali isto tako imaćemo i mogućnost automatskog prepoznavanje prisutnih uređaja u sistemu i učitavanje odgovarajućih drajvera za te uređaje (*systemd* za te potrebe koristi alat *udev*)
      >  
    - **Root filesystem overlay directories** dodaćemo putanju u kojoj želimo da se nalaze svi direktorijumi i fajlovi koje želimo da uključimo kao   *overlay*: **board/beagleboard/beagleboneai64/rootfs-overlay**.
 
      > Također, bitno je da postavimo ovu putanju, jer želimo da koristimo mogućnost *Buildroot-a* da definišemo nešto što se zove *overlay*. Na putanji *board/beagleboard/beagleboneai64* kreiramo direktorijum *rootfs-overlay*, a zatim u njega možemo dodavati proizvoljne fajlove i direktorijume koje će onda *Buildroot* prepoznati i dodati u svoj *root* fajlsistem. Na taj način ćemo kasnije dodati konfiguraciju za mrežu, kao i javni ključ potreban za *SSH* konekciju i neke druge stvari.
      > 
- U okviru **Kernel** sekcije:
    - **Kernel version** biramo opciju **Custom version** i ispod u polje **Kernel version** upisujemo željenu veriziju, u našem slučaju: **6.6.30**
    - Ostale opcije ostavljamo kao podrazumijevane:
      - **Kernel configuration** : **Use the architecture default configuration** jer smo izabrali podrazumijevani *defconfig* fajl ploče
      - **Build a Device Tree Blob (DTB)** je označeno i kao **In-tree Device Tree Source file name** je postavljeno **ti/k3-j721e-beagleboneai64**

         >
         > Ove opcije su već podrazumijevano postavljene i na taj način će *Buildroot* forsira da pri izgradnji *kernel-a* korisiti podrazumijevane *device-tree* fajlove koji se odnose na ovu ploču, kao i podrazumijevani *defconfig* fajl, koji ovde modifikujemo.
         >
        
- U okviru **Target packages** sekcije fokusiraćemo se na nekoliko podsekcija:
  -   **Audio and video applications**
      - uključićemo opciju **gstreamer 1.x** da bismo imali podršku za *gstreamer framework* 
      -   nakon izbora **gstreamer 1.x** otvoriće se niz opcija koje je moguće uključiti ili isključiti. Ostavićemo sve podrazumijevano uključene opcije takve kakve jesu, a zatim:
      -   izabraćemo opciju **gst1-plugins-good** te unutar nje izabrati redom opcije:
          -   **jpeg**
          -   **autodetect**
          -   **avi**
          -   **effectv**
          -   **udp**
          -   **videocrop**
          -   **videofilter**
          -   **v4l2**
          -   **v4l2-probe**
      - vratićemo se nazad iz **gst1-plugins-good**, a zatim ući u **gst1-plugins-bad** te unutar nje izabrati sljedeće opcije:
          - **autoconver**
          - **bayer**
          - **kmssink**
      >
      
      
      > 
      > Prethodnim opcijama dodali smo podršku za *gstreamer framework* koji će nam služiti za manipulaciju i obradu signala koje ćemo dobijati sa kamere, te prikazivati na ekranu. Također izabran je niz opcija koji u *gstreamer* dodaju razne pakete koje smo identifikovali kao potrebe pri izradi i prezentaciji projektnog zadatka, te također pri testiranju rada sistema.
      >
      
  - U podsekciji **Libraries** (nakon izlaska iz podsekcije *Audio and video applications*):
      - klikom na opciju **Graphics** otvara se niz novih opcija, potrebno je izabrati **kms++** te **Install test programs**
          - biramo opciju **libdrm**, a zatim **Install test programs**.
            
            > 
            > Izborom prethodne dvije opcije dobija se mogućnost korištenja *modetest*  te *kmsprint* i *kmstest* alata koji mogu biti jako korisni pri debagovanju
            > 
      - klikom na opciju **Hardware handling** otvara se niz opcija među kojima je potrebno  izabrati:
          - **libv4l** te **v4l-utils-tools**

            > Na ovaj način dodali smo podršku za kameru koje ćemo koristiti, u vidu skupa biblioteka koje služe kao sloj apstrakcije iznad *videoforlinux* kompatibilnih uređaja. Kao i niz *utility* funkcija za ispisivanje više informacija o uređajima i slično. Vidi [v4l](https://medium.com/@deepeshdeepakdd2/v4l-a-complete-practical-tutorial-c520f097b590).
   - U podsekciji **Networking applications** potrebno je izabrati opciju **dropbear** da bismo imali mogućnost pristupa ploči preko *SSH* protokola. 

Nakon što smo izabrali sve željene opcije, u okviru grafičkog okruženja potreno je sačuvati novu konfiguraciju te izaći iz okruženja.  
Sada ćemo pokrenuti komandu:

```
make linux-xconfig
```

Na ovaj način ćemo podesiti neke konfiguracione opcije specifične za sam *kernel* koje nismo mogli podešavati u okviru prethodne konfiguracije. 
Kada pokrenemo prethodnu komandu, prvo će se preuzeti određeni kod *kernel-a* i to one verzije koju smo specificirali u prethodnoj konfiguraciji, i to može potrajati nekoliko minuta. Nakon toga otvoriće se grafički interfejs *xconfig-a* (ili *menuconfig* ako idemo preko njega) sa konfiguracionim opcijama *kernel-a*. Tu je potrebno izabrati nekoliko bitnih opcija.





