@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventoryLedger("code-578", label: "label-805")
        let view = Pharmacy.toInventoryLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryLedgerViews([item, item]).count == 2)
    }
}
