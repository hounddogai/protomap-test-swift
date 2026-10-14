@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingSkillMixScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPendingSkillMixScore("code-941", name: "name-701")
        let view = Staffing.toPendingSkillMixScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPendingSkillMixScoreViews([item, item]).count == 2)
    }
}
