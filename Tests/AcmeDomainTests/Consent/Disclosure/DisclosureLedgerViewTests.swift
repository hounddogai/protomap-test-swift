@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newDisclosureLedger("code-976", label: "label-669")
        let view = Consent.toDisclosureLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toDisclosureLedgerViews([item, item]).count == 2)
    }
}
