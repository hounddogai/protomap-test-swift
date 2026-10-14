@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventoryAdjustment("code-74", label: "label-612")
        let view = Pharmacy.toInventoryAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryAdjustmentViews([item, item]).count == 2)
    }
}
