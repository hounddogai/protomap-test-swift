@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newAcuityPlanReview("code-138", name: "name-152")
        let view = Staffing.toAcuityPlanReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toAcuityPlanReviewViews([item, item]).count == 2)
    }
}
