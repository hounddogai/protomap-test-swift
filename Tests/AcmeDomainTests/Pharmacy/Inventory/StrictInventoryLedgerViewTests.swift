@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictInventoryLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newStrictInventoryLedger("code-280", title: "title-512")
        let view = Pharmacy.toStrictInventoryLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toStrictInventoryLedgerViews([item, item]).count == 2)
    }
}
