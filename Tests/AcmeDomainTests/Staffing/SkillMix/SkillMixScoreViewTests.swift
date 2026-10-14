@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixScore("code-435", name: "name-815")
        let view = Staffing.toSkillMixScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixScoreViews([item, item]).count == 2)
    }
}
