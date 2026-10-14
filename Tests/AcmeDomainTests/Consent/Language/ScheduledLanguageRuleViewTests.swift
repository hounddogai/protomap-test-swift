@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledLanguageRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newScheduledLanguageRule("code-894", label: "label-83")
        let view = Consent.toScheduledLanguageRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toScheduledLanguageRuleViews([item, item]).count == 2)
    }
}
