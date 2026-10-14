@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormRule("code-170", name: "name-28")
        let view = Consent.toConsentFormRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormRuleViews([item, item]).count == 2)
    }
}
