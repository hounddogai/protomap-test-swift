@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveSkillMixReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newAdaptiveSkillMixReview("code-388", label: "label-74")
        let view = Staffing.toAdaptiveSkillMixReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toAdaptiveSkillMixReviewViews([item, item]).count == 2)
    }
}
