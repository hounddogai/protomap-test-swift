@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallLedger("code-20", name: "name-519")
        let view = Pharmacy.toRecallLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallLedgerViews([item, item]).count == 2)
    }
}
