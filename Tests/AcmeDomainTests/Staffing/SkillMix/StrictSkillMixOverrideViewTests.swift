@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictSkillMixOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newStrictSkillMixOverride("code-739", name: "name-341")
        let view = Staffing.toStrictSkillMixOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toStrictSkillMixOverrideViews([item, item]).count == 2)
    }
}
