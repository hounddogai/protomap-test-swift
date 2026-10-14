@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseLedgerViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDispenseLedger("code-5", title: "title-12")
        let view = Pharmacy.toDispenseLedgerView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDispenseLedgerViews([item, item]).count == 2)
    }
}
