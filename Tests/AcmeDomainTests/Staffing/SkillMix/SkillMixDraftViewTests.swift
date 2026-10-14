@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixDraftViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixDraft("code-288", name: "name-362")
        let view = Staffing.toSkillMixDraftView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixDraftViews([item, item]).count == 2)
    }
}
