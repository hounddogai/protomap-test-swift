@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedSkillMixTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newWeightedSkillMixTemplate("code-223", label: "label-347")
        let view = Staffing.toWeightedSkillMixTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toWeightedSkillMixTemplateViews([item, item]).count == 2)
    }
}
