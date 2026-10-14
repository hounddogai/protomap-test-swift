@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventoryThreshold("code-360", title: "title-235")
        let view = Pharmacy.toInventoryThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryThresholdViews([item, item]).count == 2)
    }
}
