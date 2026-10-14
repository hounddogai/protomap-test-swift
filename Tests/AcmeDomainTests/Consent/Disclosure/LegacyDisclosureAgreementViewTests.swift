@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyDisclosureAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLegacyDisclosureAgreement("code-873", title: "title-840")
        let view = Consent.toLegacyDisclosureAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLegacyDisclosureAgreementViews([item, item]).count == 2)
    }
}
