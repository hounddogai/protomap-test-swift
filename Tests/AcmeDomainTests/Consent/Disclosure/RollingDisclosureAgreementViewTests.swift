@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingDisclosureAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRollingDisclosureAgreement("code-294", title: "title-311")
        let view = Consent.toRollingDisclosureAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRollingDisclosureAgreementViews([item, item]).count == 2)
    }
}
