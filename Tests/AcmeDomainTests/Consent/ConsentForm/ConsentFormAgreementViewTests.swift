@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormAgreement("code-923", name: "name-19")
        let view = Consent.toConsentFormAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormAgreementViews([item, item]).count == 2)
    }
}
