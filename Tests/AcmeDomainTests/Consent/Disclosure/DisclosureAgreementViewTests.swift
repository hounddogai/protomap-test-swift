@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureAgreement("code-825", title: "title-129")
        let view = Consent.toDisclosureAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureAgreementViews([item, item]).count == 2)
    }
}
