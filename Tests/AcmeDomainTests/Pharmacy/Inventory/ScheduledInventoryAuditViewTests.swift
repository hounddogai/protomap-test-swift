@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventoryAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newScheduledInventoryAudit("code-288", title: "title-332")
        let view = Pharmacy.toScheduledInventoryAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toScheduledInventoryAuditViews([item, item]).count == 2)
    }
}
