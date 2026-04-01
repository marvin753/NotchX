//
//  TeleprompterSampleText.swift
//  NotchX
//
//  Localized instructional sample texts shown in the teleprompter editor
//  on every fresh app launch so new users can immediately press Play.
//

import Foundation

enum TeleprompterSampleText {
    static let texts: [String: String] = [
        "en": """
        Welcome to the NotchX Teleprompter! This sample text is here to show you how it works. \
        There are three guidance modes you can choose from: \
        Word Tracking highlights each word as you speak it, using speech recognition to follow along. \
        Classic scrolls the text at a steady, adjustable speed — no microphone needed. \
        Voice-Activated scrolls while you speak and pauses automatically when you stop. \
        You can customize the font style, size, color, and scroll speed in Settings. \
        To begin, simply replace this text with your own script and press Play. Happy presenting!
        """,
        "de": """
        Willkommen beim NotchX Teleprompter! Dieser Beispieltext zeigt Ihnen, wie er funktioniert. \
        Es gibt drei Modi zur Auswahl: \
        Wortverfolgung hebt jedes Wort hervor, das Sie sprechen, und nutzt Spracherkennung, um Ihrem Redefluss zu folgen. \
        Klassisch scrollt den Text mit einer gleichmäßigen, einstellbaren Geschwindigkeit — kein Mikrofon nötig. \
        Sprachaktiviert scrollt, während Sie sprechen, und pausiert automatisch, wenn Sie aufhören. \
        Sie können Schriftart, Größe, Farbe und Scrollgeschwindigkeit in den Einstellungen anpassen. \
        Ersetzen Sie einfach diesen Text durch Ihr eigenes Skript und drücken Sie auf Play. Viel Erfolg beim Präsentieren!
        """,
        "fr": """
        Bienvenue dans le Téléprompter NotchX ! Ce texte d'exemple est là pour vous montrer comment il fonctionne. \
        Vous avez le choix entre trois modes de guidage : \
        Le suivi de mots met en surbrillance chaque mot que vous prononcez grâce à la reconnaissance vocale. \
        Le mode classique fait défiler le texte à une vitesse constante et réglable — pas besoin de micro. \
        Le mode activé par la voix défile pendant que vous parlez et se met en pause automatiquement quand vous vous arrêtez. \
        Vous pouvez personnaliser la police, la taille, la couleur et la vitesse de défilement dans les Réglages. \
        Pour commencer, remplacez simplement ce texte par votre propre script et appuyez sur Play. Bonne présentation !
        """,
        "es": """
        ¡Bienvenido al Teleprompter de NotchX! Este texto de ejemplo está aquí para mostrarte cómo funciona. \
        Hay tres modos de guía disponibles: \
        Seguimiento de palabras resalta cada palabra que dices, usando reconocimiento de voz para seguir tu ritmo. \
        Clásico desplaza el texto a una velocidad constante y ajustable — no necesitas micrófono. \
        Activado por voz se desplaza mientras hablas y se pausa automáticamente cuando dejas de hablar. \
        Puedes personalizar la fuente, el tamaño, el color y la velocidad de desplazamiento en Ajustes. \
        Para empezar, simplemente reemplaza este texto con tu propio guion y pulsa Play. ¡Buena presentación!
        """,
        "it": """
        Benvenuto nel Teleprompter di NotchX! Questo testo di esempio ti mostra come funziona. \
        Puoi scegliere tra tre modalità di guida: \
        Tracciamento parole evidenzia ogni parola che pronunci, usando il riconoscimento vocale per seguirti. \
        Classico scorre il testo a una velocità costante e regolabile — nessun microfono necessario. \
        Attivato dalla voce scorre mentre parli e si mette in pausa automaticamente quando ti fermi. \
        Puoi personalizzare il font, la dimensione, il colore e la velocità di scorrimento nelle Impostazioni. \
        Per iniziare, sostituisci semplicemente questo testo con il tuo copione e premi Play. Buona presentazione!
        """,
        "pt-BR": """
        Bem-vindo ao Teleprompter do NotchX! Este texto de exemplo está aqui para mostrar como ele funciona. \
        Existem três modos de orientação disponíveis: \
        Rastreamento de palavras destaca cada palavra que você fala, usando reconhecimento de voz para acompanhar seu ritmo. \
        Clássico rola o texto em uma velocidade constante e ajustável — sem necessidade de microfone. \
        Ativado por voz rola enquanto você fala e pausa automaticamente quando você para. \
        Você pode personalizar a fonte, o tamanho, a cor e a velocidade de rolagem nas Configurações. \
        Para começar, basta substituir este texto pelo seu próprio roteiro e pressionar Play. Boa apresentação!
        """,
        "nl": """
        Welkom bij de NotchX Teleprompter! Deze voorbeeldtekst laat zien hoe het werkt. \
        Er zijn drie begeleidingsmodi beschikbaar: \
        Woordherkenning markeert elk woord dat u uitspreekt en volgt uw spreektempo via spraakherkenning. \
        Klassiek scrollt de tekst op een gelijkmatige, instelbare snelheid — geen microfoon nodig. \
        Spraakgestuurd scrollt terwijl u spreekt en pauzeert automatisch wanneer u stopt. \
        U kunt het lettertype, de grootte, de kleur en de scrollsnelheid aanpassen in Instellingen. \
        Om te beginnen vervangt u deze tekst door uw eigen script en drukt u op Play. Veel succes met uw presentatie!
        """,
        "ja": """
        NotchXテレプロンプターへようこそ！このサンプルテキストで使い方をご紹介します。\
        3つのガイドモードから選べます：\
        ワードトラッキングは音声認識を使い、話した言葉を一つずつハイライトします。\
        クラシックはマイク不要で、一定の速度でテキストをスクロールします。速度は調整可能です。\
        音声起動モードは話している間スクロールし、話すのをやめると自動的に一時停止します。\
        設定からフォント、サイズ、色、スクロール速度をカスタマイズできます。\
        このテキストをご自身の原稿に置き換えて、Playを押してください。素晴らしいプレゼンテーションを！
        """,
        "zh-Hans": """
        欢迎使用 NotchX 提词器！这段示例文字将帮助您了解它的工作方式。\
        您可以选择三种引导模式：\
        逐词追踪模式利用语音识别技术，在您说出每个词时进行高亮显示。\
        经典模式以稳定且可调节的速度滚动文字，无需麦克风。\
        语音激活模式在您说话时滚动，停止说话时自动暂停。\
        您可以在设置中自定义字体样式、大小、颜色和滚动速度。\
        准备好后，请将这段文字替换为您自己的稿件，然后按下播放按钮。祝您演讲顺利！
        """,
        "ar": """
        مرحباً بك في تلقين NotchX! هذا النص التجريبي موجود ليوضح لك كيف يعمل. \
        هناك ثلاثة أوضاع إرشاد للاختيار من بينها: \
        تتبع الكلمات يُبرز كل كلمة تنطقها باستخدام التعرف على الكلام لمتابعة إيقاعك. \
        الوضع الكلاسيكي يُمرر النص بسرعة ثابتة وقابلة للتعديل — لا حاجة لميكروفون. \
        الوضع المُفعّل بالصوت يتحرك أثناء كلامك ويتوقف تلقائياً عند توقفك عن الحديث. \
        يمكنك تخصيص نمط الخط والحجم واللون وسرعة التمرير من الإعدادات. \
        للبدء، استبدل هذا النص بنصك الخاص واضغط على تشغيل. تقديم موفق!
        """,
        "cs": """
        Vítejte v teleprompéru NotchX! Tento ukázkový text vám ukazuje, jak to funguje. \
        Můžete si vybrat ze tří režimů navádění: \
        Sledování slov zvýrazňuje každé slovo, které vyslovíte, pomocí rozpoznávání řeči. \
        Klasický režim posouvá text konstantní a nastavitelnou rychlostí — mikrofon není potřeba. \
        Hlasově aktivovaný režim posouvá text, když mluvíte, a automaticky se zastaví, když přestanete. \
        V Nastavení si můžete přizpůsobit písmo, velikost, barvu a rychlost posouvání. \
        Chcete-li začít, jednoduše nahraďte tento text vlastním scénářem a stiskněte Play. Hodně úspěchů při prezentaci!
        """,
        "hu": """
        Üdvözöljük a NotchX Teleprompterben! Ez a példaszöveg megmutatja, hogyan működik. \
        Három irányítási mód közül választhat: \
        A szókövetés kiemeli minden egyes kimondott szavát, hangfelismerés segítségével követve az Ön beszédét. \
        A klasszikus mód egyenletes, állítható sebességgel görgeti a szöveget — mikrofon nem szükséges. \
        A hangvezérelt mód görget, amíg Ön beszél, és automatikusan megáll, ha abbahagyja. \
        A Beállításokban testreszabhatja a betűtípust, méretet, színt és görgetési sebességet. \
        A kezdéshez egyszerűen cserélje ki ezt a szöveget a saját szövegére, és nyomja meg a Lejátszás gombot. Sikeres prezentálást!
        """,
        "ko": """
        NotchX 텔레프롬프터에 오신 것을 환영합니다! 이 예시 텍스트는 작동 방식을 보여드리기 위해 준비되었습니다. \
        세 가지 가이드 모드를 선택할 수 있습니다: \
        단어 추적 모드는 음성 인식을 사용하여 말하는 각 단어를 하이라이트합니다. \
        클래식 모드는 일정하고 조절 가능한 속도로 텍스트를 스크롤합니다 — 마이크가 필요 없습니다. \
        음성 활성화 모드는 말하는 동안 스크롤되고 말을 멈추면 자동으로 일시 정지됩니다. \
        설정에서 글꼴 스타일, 크기, 색상 및 스크롤 속도를 맞춤 설정할 수 있습니다. \
        시작하려면 이 텍스트를 자신의 대본으로 교체하고 재생을 누르세요. 멋진 발표가 되길 바랍니다!
        """,
        "pl": """
        Witaj w Teleprompterze NotchX! Ten przykładowy tekst pokazuje, jak to działa. \
        Do wyboru są trzy tryby prowadzenia: \
        Śledzenie słów podświetla każde wypowiadane słowo, korzystając z rozpoznawania mowy. \
        Tryb klasyczny przewija tekst ze stałą, regulowaną prędkością — mikrofon nie jest potrzebny. \
        Tryb aktywowany głosem przewija tekst, gdy mówisz, i automatycznie zatrzymuje się, gdy przestaniesz. \
        W Ustawieniach możesz dostosować czcionkę, rozmiar, kolor i prędkość przewijania. \
        Aby zacząć, po prostu zamień ten tekst na własny scenariusz i naciśnij Play. Powodzenia w prezentacji!
        """,
        "ru": """
        Добро пожаловать в Телепромптер NotchX! Этот пример текста покажет вам, как он работает. \
        Доступны три режима сопровождения: \
        Отслеживание слов подсвечивает каждое произнесённое вами слово с помощью распознавания речи. \
        Классический режим прокручивает текст с постоянной настраиваемой скоростью — микрофон не нужен. \
        Голосовой режим прокручивает текст, пока вы говорите, и автоматически останавливается, когда вы замолкаете. \
        В Настройках вы можете изменить шрифт, размер, цвет и скорость прокрутки. \
        Чтобы начать, просто замените этот текст на свой сценарий и нажмите Play. Удачной презентации!
        """,
        "tr": """
        NotchX Teleprompter'a hoş geldiniz! Bu örnek metin, nasıl çalıştığını göstermek için burada. \
        Üç rehberlik modu arasından seçim yapabilirsiniz: \
        Kelime Takibi, konuşma tanıma ile söylediğiniz her kelimeyi vurgular. \
        Klasik mod, metni sabit ve ayarlanabilir bir hızda kaydırır — mikrofon gerekmez. \
        Sesle Etkinleştirme modu, siz konuşurken kaydırır ve durduğunuzda otomatik olarak duraklar. \
        Ayarlar'dan yazı tipini, boyutu, rengi ve kaydırma hızını özelleştirebilirsiniz. \
        Başlamak için bu metni kendi metninizle değiştirin ve Oynat'a basın. Başarılı sunumlar!
        """,
        "uk": """
        Ласкаво просимо до Телепромптера NotchX! Цей зразковий текст покаже вам, як він працює. \
        Доступні три режими супроводу: \
        Відстеження слів підсвічує кожне вимовлене вами слово за допомогою розпізнавання мовлення. \
        Класичний режим прокручує текст з постійною регульованою швидкістю — мікрофон не потрібен. \
        Голосовий режим прокручує текст, поки ви говорите, і автоматично зупиняється, коли ви замовкаєте. \
        У Налаштуваннях ви можете змінити шрифт, розмір, колір та швидкість прокрутки. \
        Щоб почати, просто замініть цей текст на свій сценарій і натисніть Play. Успішної презентації!
        """
    ]

    /// Returns the localized sample text based on the app's UI language.
    /// Fallback chain: exact match → language prefix → English.
    static var localizedText: String {
        let preferred = Bundle.main.preferredLocalizations.first ?? "en"

        // 1. Exact match (e.g., "pt-BR", "zh-Hans")
        if let text = texts[preferred] { return text }

        // 2. Language prefix fallback (e.g., "en-GB" → "en")
        let prefix = String(preferred.prefix(2))
        if let text = texts[prefix] { return text }

        // 3. Ultimate fallback: English
        return texts["en"]!
    }
}
