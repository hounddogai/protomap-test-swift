@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedInventoryBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newBatchedInventoryBaseline("code-445", label: "label-89")
        let view = Pharmacy.toBatchedInventoryBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toBatchedInventoryBaselineViews([item, item]).count == 2)
    }
}
