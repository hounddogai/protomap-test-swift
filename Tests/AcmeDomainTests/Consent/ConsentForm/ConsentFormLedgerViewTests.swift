@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newConsentFormLedger("code-836", title: "title-284")
        let view = Consent.toConsentFormLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toConsentFormLedgerViews([item, item]).count == 2)
    }
}
