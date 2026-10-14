@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixClaim("code-227", title: "title-632")
        let view = Staffing.toSkillMixClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixClaimViews([item, item]).count == 2)
    }
}
