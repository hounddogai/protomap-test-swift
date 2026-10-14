@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLanguageRule("code-58", title: "title-340")
        let view = Consent.toLanguageRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLanguageRuleViews([item, item]).count == 2)
    }
}
