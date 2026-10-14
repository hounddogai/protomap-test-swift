@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackSkillMixTemplateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFallbackSkillMixTemplate("code-447", label: "label-132")
        let view = Staffing.toFallbackSkillMixTemplateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFallbackSkillMixTemplateViews([item, item]).count == 2)
    }
}
