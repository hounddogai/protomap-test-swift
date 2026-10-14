@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimarySkillMixCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPrimarySkillMixCycle("code-375", name: "name-567")
        let view = Staffing.toPrimarySkillMixCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPrimarySkillMixCycleViews([item, item]).count == 2)
    }
}
