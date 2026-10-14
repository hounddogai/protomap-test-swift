@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalInventoryRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRegionalInventoryRollup("code-364", label: "label-587")
        let view = Pharmacy.toRegionalInventoryRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRegionalInventoryRollupViews([item, item]).count == 2)
    }
}
