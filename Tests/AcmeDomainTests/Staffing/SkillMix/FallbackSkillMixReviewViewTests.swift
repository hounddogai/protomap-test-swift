@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackSkillMixReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFallbackSkillMixReview("code-650", name: "name-376")
        let view = Staffing.toFallbackSkillMixReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFallbackSkillMixReviewViews([item, item]).count == 2)
    }
}
