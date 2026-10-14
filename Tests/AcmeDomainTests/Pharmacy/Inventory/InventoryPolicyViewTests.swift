@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventoryPolicy("code-70", name: "name-626")
        let view = Pharmacy.toInventoryPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryPolicyViews([item, item]).count == 2)
    }
}
