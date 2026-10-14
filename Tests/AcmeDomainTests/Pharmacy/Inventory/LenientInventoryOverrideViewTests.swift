@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInventoryOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLenientInventoryOverride("code-729", label: "label-227")
        let view = Pharmacy.toLenientInventoryOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLenientInventoryOverrideViews([item, item]).count == 2)
    }
}
