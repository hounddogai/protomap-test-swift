@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledSkillMixEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newScheduledSkillMixEstimate("code-972", label: "label-44")
        let view = Staffing.toScheduledSkillMixEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toScheduledSkillMixEstimateViews([item, item]).count == 2)
    }
}
