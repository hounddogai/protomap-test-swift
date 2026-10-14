@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedSkillMixCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newCappedSkillMixCycle("code-602", title: "title-839")
        let view = Staffing.toCappedSkillMixCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toCappedSkillMixCycleViews([item, item]).count == 2)
    }
}
