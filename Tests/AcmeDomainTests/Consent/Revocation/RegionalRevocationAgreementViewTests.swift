@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalRevocationAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRegionalRevocationAgreement("code-823", label: "label-311")
        let view = Consent.toRegionalRevocationAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRegionalRevocationAgreementViews([item, item]).count == 2)
    }
}
