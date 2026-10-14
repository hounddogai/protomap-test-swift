@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedConsentFormRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newCappedConsentFormRule("code-799", name: "name-259")
        let view = Consent.toCappedConsentFormRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toCappedConsentFormRuleViews([item, item]).count == 2)
    }
}
