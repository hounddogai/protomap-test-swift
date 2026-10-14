@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInteractionLedger("code-346", name: "name-326")
        let view = Pharmacy.toInteractionLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInteractionLedgerViews([item, item]).count == 2)
    }
}
