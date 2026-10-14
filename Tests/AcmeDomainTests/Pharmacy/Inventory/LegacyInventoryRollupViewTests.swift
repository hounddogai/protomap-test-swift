@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInventoryRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLegacyInventoryRollup("code-352", label: "label-163")
        let view = Pharmacy.toLegacyInventoryRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLegacyInventoryRollupViews([item, item]).count == 2)
    }
}
