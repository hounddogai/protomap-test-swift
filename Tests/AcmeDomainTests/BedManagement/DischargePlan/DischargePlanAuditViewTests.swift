@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newDischargePlanAudit("code-538", title: "title-357")
        let view = BedManagement.toDischargePlanAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toDischargePlanAuditViews([item, item]).count == 2)
    }
}
