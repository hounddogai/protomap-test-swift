@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveLanguageTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newAdaptiveLanguageTemplate("code-528", title: "title-921")
        let view = Consent.toAdaptiveLanguageTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toAdaptiveLanguageTemplateViews([item, item]).count == 2)
    }
}
