@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventoryBaseline("code-504", label: "label-969")
        let view = Pharmacy.toInventoryBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryBaselineViews([item, item]).count == 2)
    }
}
