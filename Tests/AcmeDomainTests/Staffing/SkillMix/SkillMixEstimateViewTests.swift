@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixEstimate("code-42", title: "title-923")
        let view = Staffing.toSkillMixEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixEstimateViews([item, item]).count == 2)
    }
}
