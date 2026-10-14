@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictSkillMixAuditViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newStrictSkillMixAudit("code-759", name: "name-642")
        let view = Staffing.toStrictSkillMixAuditView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toStrictSkillMixAuditViews([item, item]).count == 2)
    }
}
