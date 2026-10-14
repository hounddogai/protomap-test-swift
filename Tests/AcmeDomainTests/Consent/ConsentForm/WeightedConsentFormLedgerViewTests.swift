@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedConsentFormLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWeightedConsentFormLedger("code-745", name: "name-590")
        let view = Consent.toWeightedConsentFormLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWeightedConsentFormLedgerViews([item, item]).count == 2)
    }
}
