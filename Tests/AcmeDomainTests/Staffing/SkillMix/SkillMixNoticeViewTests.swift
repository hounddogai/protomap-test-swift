@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixNotice("code-56", name: "name-376")
        let view = Staffing.toSkillMixNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixNoticeViews([item, item]).count == 2)
    }
}
