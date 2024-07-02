# Projektni zadadatak iz predmeta Ugrađeni računarski sistemi

Tekst specifikacije projektnog zadatka se nalazi na repozitorijumu u fajlu *assignment.txt*.  
Proces rada i koraci koji su neophodnu za realizaciju traženog zadatka biće opisani u ovom tekstu.

## Preduslovi za izradu zadatka
1. BeagleBone AI 64 razvojna ploča sa napajanjem i eventualno kablom za povezivanje sa UART serijskim interfejsom na ploči
2. kabl sa mini DisplayPort konektorom na jednoj strani za povezivanje sa BB AI64
3. USB kamera ili CSI kamera (ako se koristi CSI kamera potrebno je imati i odgovarajući kabl sa 22-pinskim konektorom za povezivanje na BB AI64)
4. SD kartica
5. LAB kabl za povezivanje razvojnog računara i BB AI64

## Izrada zadatka
Na samom početku potrebno je odlučiti na koji način će se generisati *build* sistem za BB AI64 ploču, to podrazumijeva generisanje *toolchain-a*, *bootloader-a*, *kernel-a*, te *root* fajlsistema. U našemu slučaju za generisanje svih potrebnih komponenata izabran je *Buildroot* alat. 

### Generisanje sistema *Buildroot* alatom
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

U ovoj verziji *Buildroot-a* postoji predefinisana konfiguracija koja uključuje neka osnovna podešavanje za ploču BB AI64. Ona se nalazi u folderu `<buildroot-folder>/configs` (kao niz drugih konfiguracija za neke druge razvojne ploče itd.) pod imenom *beagleboneai64_defconfig*.  
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
  - možemo provjeriti **Location to save buildroot config** da vidimo gdje će biti sačuvana ova izmjene konfiguracija. Ukoliko ostavimo podrazumijevanu putanju, izmjenjena konfiguracija će pregaziti postojeću osnovnu konfiguraciju.
- U okviru **System configuration** sekcije:
    - **System hostname** možemo podesiti na **urs**
    - **System banner** na **Welcome to URS**
    - **Init system** ćemo postaviti na **systemd**

      > Bitno je da izaberemo *systemd* kao inicijalizacioni sistem, jer ćemo na taj način moći iskorisiti skrite za inicijalizaciju koje se nalaze u folderu ploče `<buildroot-folder>/board/beagleboard/beagleboneai64`, ali isto tako imaćemo i mogućnost automatskog prepoznavanje prisutnih uređaja u sistemu i učitavanje odgovarajućih drajvera za te uređaje (*systemd* za te potrebe koristi alat *udev*)
      >  
    - **Root filesystem overlay directories** dodaćemo putanju u kojoj želimo da se nalaze svi direktorijumi i fajlovi koje želimo da uključimo kao   *overlay*: **board/beagleboard/beagleboneai64/rootfs-overlay**.
 
      > Također, bitno je da postavimo ovu putanju, jer želimo da koristimo mogućnost *Buildroot-a* da definišemo nešto što se zove *overlay*. Na putanji `<buildroot-folder>/board/beagleboard/beagleboneai64/` kreiramo direktorijum `rootfs-overlay`, a zatim u njega možemo dodavati proizvoljne fajlove i direktorijume koje će onda *Buildroot* prepoznati i dodati u svoj *root filesystem*. Na taj način ćemo kasnije dodati konfiguraciju za mrežu, kao i javni ključ potreban za *SSH* konekciju i neke druge stvari.
      > 
- U okviru **Kernel** sekcije:
    - **Kernel version** biramo opciju **Custom version** i ispod u polje **Kernel version** upisujemo željenu veriziju, u našem slučaju: **6.6.30**
    - Ostale opcije ostavljamo kao podrazumijevane:
      - **Kernel configuration** : **Use the architecture default configuration** jer smo izabrali podrazumijevani *defconfig* fajl ploče
      - **Build a Device Tree Blob (DTB)** je označeno i kao **In-tree Device Tree Source file name** je postavljeno **ti/k3-j721e-beagleboneai64**

         >
         > Ove opcije su već podrazumijevano postavljene i na taj način se *Buildroot* forsira da pri izgradnji *kernel-a* korisiti podrazumijevane *device-tree* fajlove koji se odnose na ovu ploču, kao i podrazumijevani *defconfig* fajl.
         >
        
- U okviru **Target packages** sekcije fokusiraćemo se na nekoliko podsekcija:
  -   **Audio and video applications**
      - uključićemo opciju **gstreamer 1.x** da bismo imali podršku za *gstreamer framework* 
      -   nakon izbora **gstreamer 1.x** otvoriće se niz opcija koje je moguće uključiti ili isključiti. Ostavićemo sve podrazumijevano uključene opcije takve kakve jesu, a zatim:
      -   treba kliknuti na **gst1-plugins-good** te u novom meniju izabrati redom opcije:
          -   **jpeg**
          -   **autodetect**
          -   **avi**
          -   **effectv**
          -   **udp**
          -   **videocrop**
          -   **videofilter**
          -   **v4l2**
          -   **v4l2-probe**
      - vratićemo se nazad iz **gst1-plugins-good**, a zatim ući u **gst1-plugins-bad** te  izabrati sljedeće opcije:
          - **autoconver**
          - **bayer**
          - **kmssink**
      >
      
      
      > 
      > Prethodnim opcijama dodali smo podršku za *gstreamer framework* koji će nam služiti za manipulaciju i obradu signala koje ćemo dobijati sa kamere, te prikazivati na ekranu. Takođe, izabran je niz opcija koji u *gstreamer* dodaju razne pakete koje smo identifikovali kao potrebne pri izradi i prezentaciji projektnog zadatka, te takođe pri testiranju rada sistema.
      >
      
  - U podsekciji **Libraries** (nakon izlaska iz podsekcije *Audio and video applications*):
      - klikom na opciju **Graphics** otvara se niz novih opcija, potrebno je izabrati **kms++** te **Install test programs**
          - biramo opciju **libdrm**, a zatim **Install test programs**.
            
            > 
            > Izborom prethodne dvije opcije dobija se mogućnost korištenja *modetest*  te *kmsprint* i *kmstest* alata koji mogu biti jako korisni pri debagovanju
            > 
      - klikom na opciju **Hardware handling** otvara se niz opcija među kojima je potrebno  izabrati:
          - **libv4l** te **v4l-utils-tools**

            > Na ovaj način dodali smo podršku za kameru koje ćemo koristiti, i to u vidu skupa biblioteka koje služe kao sloj apstrakcije iznad *videoforlinux* kompatibilnih uređaja. Kao i niz *utility* funkcija za ispisivanje više informacija o * uređajima i slično. Vidi [v4l](https://medium.com/@deepeshdeepakdd2/v4l-a-complete-practical-tutorial-c520f097b590).
   - U podsekciji **Networking applications** potrebno je izabrati opciju **dropbear** da bismo imali mogućnost pristupa ploči preko *SSH* protokola. 

Nakon što smo izabrali sve željene opcije, u okviru konfiguracionog grafičkog okruženja potreno je sačuvati novu konfiguraciju te izaći iz okruženja.  
Sada ćemo pokrenuti komandu:

```
make linux-xconfig
```

Na ovaj način ćemo podesiti neke konfiguracione opcije specifične za sam *kernel* koje nismo mogli podešavati u okviru prethodne konfiguracije. 
Kada pokrenemo prethodnu komandu, prvo će se preuzeti određeni kod *kernel-a* i to one verzije koju smo specificirali u prethodnoj konfiguraciji, i to može potrajati nekoliko minuta. Nakon toga otvoriće se grafički interfejs *xconfig-a* (ili *menuconfig* ako idemo preko njega) sa konfiguracionim opcijama *kernel-a*. Tu je potrebno izabrati nekoliko bitnih opcija.

U okviru **Device Drivers** sekcije
   - A zatim u okviru **Graphics support**
       - uključiti opciju **Direct Rendering Manager (XFree 4.1.0 and higher DRI support)**,
       - a nakon toga klikom na *Graphics support* otvoriće se sa desne strane niz opcija
           - uključiti opciju **DRM Support for TI keystone**
        
             >
             >  Na ovaj način uključili smo podršku u vidu drajvera za *DSS - Display SubSystem* i to konkretno za sve platforme koje su dio *j721e* *Texas instruments* arhitekture, u koju spada i *SoC TDA4VM* koji se nalazi na našoj ploči. Konkretan naziv drajvera je *tidss* i on služi za dohvatanje i iscrtavanje piksela na ekran. Više informacija može se naći u zvaničnoj dokumentaciji vezanoj za sam *SoC* [TDA4VM](https://software-dl.ti.com/jacinto7/esd/processor-sdk-linux-sk-tda4vm/09_02_00/exports/docs/linux/Foundational_Components/Kernel/Kernel_Drivers/Display/DSS7.html)
             >
         - kliknuti na **Display Interface Bridges**
             - izabrati opciju **Display connector support**
        
               >
               > Omogućavanje drajvera za konektore displeja sa mogućnošću *hot-plug* rada.
               >
             - izabrati opciju **Cadence DPI/DP bridge**, a zatim i **J721E Cadence DPI/DP wrapper support**
          
               >
               > Omogućavanje podrške za *J721E* platforme u vidu podešavanja internog *DPI/DP bridge-a*, te inicijalizacije nekih osnovnih podešavanje vezanih za *DisplayPort* interfejs koji mi koristimo za prikazivanje video strima na ekranu.
               >

Nakon što smo podesili konfiguraciju vezanu za *kernel*, prije svega smo se bavili uključivanjem podrške za prikaz slike na ekran preko *DisplayPort* konektora, ostale stvari ostavljamo kako jesu i sačuvamo ovu konfiguraciju, te zatvorimo *config* grafički interfejs.

  
Sada, konačno možemo izgraditi sistem. Pokrećemo komandu:
```
make
```

i čekamo nekoliko sati da se generišu potrebni artifakti.  

Kada je izgradnja gotova, u `<buildroot-folder>/output/images` folderu biće generisan fajl `sdcard.img`. U ovom fajlu imamo kompletnu generisanu sliku SD kartice koju je potrebno samo instalirati na karticu. To možemo uraditi *Linux* komandom *dd*.  

Međutim prije toga potrebno je odraditi nekoliko stvari. 
Pošto želimo da imamo mogućnost SSH konekcije sa pločom, a ranije smo u konfiguraciji definisali folder `<buildroot-folder>/board/beagleboard/beagleboneai64/rootfs-overlay` unutar kojeg možemo specificirati sve foldere i fajlove koje želimo da nam budu *overlay* postojećeg *root filesystem-a*. Potrebno je uraditi sljedeće.  

Prvo treba generisati *SSH* ključ koji će nam služiti za konekciju sa pločom.

```
ssh-keygen -t rsa -b 4096 
```
kojom će se generisati par privatni-javni ključ na razvojnoj mašini u vidu dva fajla. A onda na ćemo na putanji `<buildroot-folder>/board/beagleboard/beagleboneai64/rootfs-overlay` kreirati direktorijum `/root/.ssh` i njemu fajl `authorized_keys`, te zatim u njega kopirati javni ključ koji smo prethodno generisali. 

```
cd `<buildroot-folder>/board/beagleboard/beagleboneai64/rootfs-overlay`
mkdir -p /root/.ssh
cd `<folder-with-ssh-key>
cp id_rsa.pub cd `<buildroot-folder>/board/beagleboard/beagleboneai64/rootfs-overlay/root/.ssh/authorized_keys`

```

Na ovaj način smo preko *overlay-a* omogućili da se na *root filesystem-u* ploče nađe javni *SSH* ključ i omogućili podršku za *SSH* konekciju.

Ali to nije dovoljno. Potrebno je da ploča ima mrežnu konekciju da bi se mogao koristiti *SSH* protokol. To možemo uraditi tako što se pomoću *UART* kabla povežemo na ploču i uradimo to ručno komandom *ifconfig*, međutim postoji i elegantniji način. 
Za ovaj posao možemo iskoristiti *systemd* infrastrukturu, tako što kreiramo konfiguracioni fajl koji podešava mrežni interfejs i smjestimo ga na *root filesystem* ploče. Smještanje na *root filesystem* ćemo obaviti već objašnjenim načinom koristeći *overlay*. 
Dakle:

```
cd `<buildroot-folder>/board/beagleboard/beagleboneai64/rootfs-overlay`
mkdir -p etc/systemd/network
touch etc/systemd/network/70-static.network

```

Nakon toga u fajl 70-static.network upišemo sljedeći sadržaj:

```
[Match]
Name=eth0

[Network]
Address=192.168.21.100/24
Gateway=192.168.21.1
```
Ostaje još da se na razvojnom računaru podesi statička *IP* adresa, koju možemo postaviti na npr. 192.168.21.101 uz *Netmask* 255.255.255.0.
Ponovo pokrenemo **make** komandu da bi se primjenile promjene koje smo napravili u *root filesystem-u*, te ponovo kopiramo *sdcard.img* na *SD* karticu. 

```
sudo dd if=sdcard.img of=/dev/sdX bs=1M
```

Ubacimo karticu na ploču i pokrenemo proces *boot-anja* ploče. 

> [!IMPORTANT]
> Prilikom pokretanja ploče potrebno je držati taster *BOOT* na ploči prilikom povezivanja napajanja. Na ovaj način govorimo ploči da želimo da se pokreće sistem koji se nalazi na *SD* kartici, a ne da se pokrene podrazumijevni operativni sistem sa *eMMC* memorije ploče, koji dolazi predefinisan.
> Više o procesu *boot-anja* ploče na [linku](https://docs.beagleboard.org/latest/boards/beaglebone/ai-64/01-introduction.html).

Kada se ploča pokrene, možemo ostvariti *SSH* konekciju sa pločom sljedećom komandom.

```
cd `<folder-with-private-ssh-key>
ssh -i id_rsa root@192.168.21.100
```

Gdje je *id_rsa* fajl u kojem se nalazi prethodno generisani privatni ključ.

> [!NOTE]
> Za ostvarivanje *SSH* komunikacije potrebno je prethodno imati podešenu statičku *IP* adresu, te fizičku vezu *LAN* kablom izmeđeu razvojnog računara i platforme.
>





             
               





