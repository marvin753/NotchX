//
//  TeleprompterPreviewTexts.swift
//  NotchX
//
//  Preview sample texts for the teleprompter settings preview.
//

import Foundation

enum TeleprompterPreviewTexts {
    static let texts: [String: String] = [
        "en": "Welcome to your teleprompter. Speaking clearly and at a comfortable pace helps your audience follow along with ease. As you present, let your words flow naturally, making eye contact with your viewers. A great presenter is not someone who reads perfectly, but someone who connects genuinely. Take a breath, trust your preparation, and let your message carry the room with confidence.",
        "de": "Willkommen bei Ihrem Teleprompter. Wenn Sie klar und in einem angenehmen Tempo sprechen, können Ihr Publikum Ihnen mühelos folgen. Beim Präsentieren lassen Sie Ihre Worte natürlich fließen und halten Sie Blickkontakt mit Ihren Zuschauern. Ein guter Redner ist nicht jemand, der perfekt vorliest, sondern jemand, der echte Verbindungen schafft. Atmen Sie tief durch, vertrauen Sie Ihrer Vorbereitung und lassen Sie Ihre Botschaft überzeugen.",
        "fr": "Bienvenue sur votre prompteur. Parler clairement et à un rythme confortable aide votre audience à vous suivre sans effort. Lors de votre présentation, laissez vos mots couler naturellement tout en maintenant le contact visuel avec vos spectateurs. Un grand orateur n'est pas celui qui lit parfaitement, mais celui qui crée de vraies connexions. Respirez, faites confiance à votre préparation et laissez votre message convaincre la salle.",
        "es": "Bienvenido a su teleprónter. Hablar con claridad y a un ritmo cómodo ayuda a su audiencia a seguirle con facilidad. Al presentar, deje que sus palabras fluyan de manera natural, manteniendo contacto visual con sus espectadores. Un gran orador no es alguien que lee perfectamente, sino alguien que conecta de verdad. Respire profundo, confíe en su preparación y deje que su mensaje llene la sala con convicción.",
        "it": "Benvenuto nel tuo teleprompter. Parlare in modo chiaro e a un ritmo confortevole aiuta il tuo pubblico a seguirti con facilità. Durante la presentazione, lascia fluire le parole in modo naturale, mantenendo il contatto visivo con i tuoi spettatori. Un grande oratore non è chi legge perfettamente, ma chi crea connessioni autentiche. Respira, fidati della tua preparazione e lascia che il tuo messaggio conquisti la platea.",
        "pt": "Bem-vindo ao seu teleprompter. Falar com clareza e num ritmo confortável ajuda o seu público a acompanhá-lo com facilidade. Ao apresentar, deixe as palavras fluir naturalmente, mantendo contacto visual com os seus espectadores. Um grande orador não é alguém que lê perfeitamente, mas alguém que cria ligações genuínas. Respire fundo, confie na sua preparação e deixe que a sua mensagem encha a sala com convicção.",
        "nl": "Welkom bij uw teleprompter. Duidelijk en in een comfortabel tempo spreken helpt uw publiek u moeiteloos te volgen. Laat tijdens uw presentatie uw woorden natuurlijk stromen terwijl u oogcontact maakt met uw kijkers. Een goede spreker is niet iemand die perfect voorleest, maar iemand die echte verbindingen legt. Adem diep in, vertrouw op uw voorbereiding en laat uw boodschap de zaal overtuigen.",
        "ja": "テレプロンプターへようこそ。はっきりと、心地よいペースで話すことで、聴衆は自然についてきます。プレゼンテーション中は、言葉を自然に流し、視聴者と目を合わせるよう心がけましょう。優れたプレゼンターとは、完璧に読み上げる人ではなく、心からつながることができる人です。深呼吸して、準備を信頼し、あなたのメッセージで会場を引きつけてください。",
        "zh-Hans": "欢迎使用您的提词器。清晰、自然地讲话，保持舒适的节奏，能帮助观众轻松跟上您的思路。在演讲时，让语言自然流淌，并与观众保持眼神交流。优秀的演讲者不在于读得有多完美，而在于能否真诚地与听众建立连接。深呼吸，相信自己的准备，让您的信息充满力量地传递到每一位观众心中。"
    ]

    static func languageCode(from localeIdentifier: String) -> String {
        let locale = Locale(identifier: localeIdentifier)
        let lang = locale.language.languageCode?.identifier ?? "en"
        if let script = locale.language.script?.identifier {
            return "\(lang)-\(script)"
        }
        return lang
    }
}
