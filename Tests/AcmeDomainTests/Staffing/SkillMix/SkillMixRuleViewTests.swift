@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixRuleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixRule("code-998", name: "name-735")
        let view = Staffing.toSkillMixRuleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixRuleViews([item, item]).count == 2)
    }
}
