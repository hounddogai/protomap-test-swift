@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventoryTier("code-231", label: "label-668")
        let view = Pharmacy.toInventoryTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryTierViews([item, item]).count == 2)
    }
}
