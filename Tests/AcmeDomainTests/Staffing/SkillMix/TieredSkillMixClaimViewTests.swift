@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredSkillMixClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newTieredSkillMixClaim("code-34", name: "name-785")
        let view = Staffing.toTieredSkillMixClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toTieredSkillMixClaimViews([item, item]).count == 2)
    }
}
