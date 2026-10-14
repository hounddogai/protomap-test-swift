@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventoryRollup("code-139", name: "name-472")
        let view = Pharmacy.toInventoryRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryRollupViews([item, item]).count == 2)
    }
}
