@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackLanguageTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newFallbackLanguageTemplate("code-866", title: "title-38")
        let view = Consent.toFallbackLanguageTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toFallbackLanguageTemplateViews([item, item]).count == 2)
    }
}
