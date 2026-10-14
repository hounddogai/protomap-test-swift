@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventoryBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newScheduledInventoryBaseline("code-611", name: "name-494")
        let view = Pharmacy.toScheduledInventoryBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toScheduledInventoryBaselineViews([item, item]).count == 2)
    }
}
