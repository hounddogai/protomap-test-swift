@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixRequestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixRequest("code-177", name: "name-715")
        let view = Staffing.toSkillMixRequestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixRequestViews([item, item]).count == 2)
    }
}
