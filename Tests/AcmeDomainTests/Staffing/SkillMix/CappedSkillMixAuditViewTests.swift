@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedSkillMixAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCappedSkillMixAudit("code-318", label: "label-772")
        let view = Staffing.toCappedSkillMixAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCappedSkillMixAuditViews([item, item]).count == 2)
    }
}
