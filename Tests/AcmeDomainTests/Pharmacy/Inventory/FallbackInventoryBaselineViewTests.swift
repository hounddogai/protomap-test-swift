@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackInventoryBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newFallbackInventoryBaseline("code-691", name: "name-759")
        let view = Pharmacy.toFallbackInventoryBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toFallbackInventoryBaselineViews([item, item]).count == 2)
    }
}
