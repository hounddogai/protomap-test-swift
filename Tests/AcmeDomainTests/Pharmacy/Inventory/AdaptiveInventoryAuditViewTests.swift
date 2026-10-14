@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveInventoryAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newAdaptiveInventoryAudit("code-346", name: "name-605")
        let view = Pharmacy.toAdaptiveInventoryAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toAdaptiveInventoryAuditViews([item, item]).count == 2)
    }
}
