@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventoryOverride("code-588", title: "title-790")
        let view = Pharmacy.toInventoryOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryOverrideViews([item, item]).count == 2)
    }
}
