@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalTransferAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newGlobalTransferAudit("code-667", name: "name-33")
        let view = BedManagement.toGlobalTransferAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toGlobalTransferAuditViews([item, item]).count == 2)
    }
}
