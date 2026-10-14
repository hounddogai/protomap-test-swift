@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredLanguageTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newTieredLanguageTemplate("code-516", title: "title-260")
        let view = Consent.toTieredLanguageTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toTieredLanguageTemplateViews([item, item]).count == 2)
    }
}
