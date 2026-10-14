@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixPreferenceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixPreference("code-449", label: "label-404")
        let view = Staffing.toSkillMixPreferenceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixPreferenceViews([item, item]).count == 2)
    }
}
