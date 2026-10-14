@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newSkillMixReview("code-963", name: "name-626")
        let view = Staffing.toSkillMixReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toSkillMixReviewViews([item, item]).count == 2)
    }
}
