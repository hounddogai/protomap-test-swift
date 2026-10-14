@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalSkillMixProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newRegionalSkillMixProfile("code-837", name: "name-892")
        let view = Staffing.toRegionalSkillMixProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toRegionalSkillMixProfileViews([item, item]).count == 2)
    }
}
