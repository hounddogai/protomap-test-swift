@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAssessmentReview("code-922", title: "title-998")
        let view = CareManagement.toAssessmentReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAssessmentReviewViews([item, item]).count == 2)
    }
}
