@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixWindowViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixWindow("code-963", title: "title-468")
        let view = Staffing.toSkillMixWindowView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixWindowViews([item, item]).count == 2)
    }
}
