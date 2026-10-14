@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedInventoryAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newWeightedInventoryAudit("code-261", name: "name-338")
        let view = Pharmacy.toWeightedInventoryAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toWeightedInventoryAuditViews([item, item]).count == 2)
    }
}
