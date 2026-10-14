@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRevocationAgreement("code-273", label: "label-170")
        let view = Consent.toRevocationAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRevocationAgreementViews([item, item]).count == 2)
    }
}
