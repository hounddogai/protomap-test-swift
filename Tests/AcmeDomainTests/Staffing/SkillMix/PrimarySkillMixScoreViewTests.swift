@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimarySkillMixScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPrimarySkillMixScore("code-692", name: "name-555")
        let view = Staffing.toPrimarySkillMixScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPrimarySkillMixScoreViews([item, item]).count == 2)
    }
}
