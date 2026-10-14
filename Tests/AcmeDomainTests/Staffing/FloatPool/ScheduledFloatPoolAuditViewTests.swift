@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledFloatPoolAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newScheduledFloatPoolAudit("code-898", label: "label-291")
        let view = Staffing.toScheduledFloatPoolAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toScheduledFloatPoolAuditViews([item, item]).count == 2)
    }
}
