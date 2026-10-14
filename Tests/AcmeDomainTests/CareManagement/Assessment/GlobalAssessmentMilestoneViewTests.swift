@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalAssessmentMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newGlobalAssessmentMilestone("code-472", title: "title-786")
        let view = CareManagement.toGlobalAssessmentMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toGlobalAssessmentMilestoneViews([item, item]).count == 2)
    }
}
