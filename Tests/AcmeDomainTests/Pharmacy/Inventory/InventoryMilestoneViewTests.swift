@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventoryMilestone("code-175", name: "name-899")
        let view = Pharmacy.toInventoryMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryMilestoneViews([item, item]).count == 2)
    }
}
