@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackAssessmentMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newFallbackAssessmentMilestone("code-366", name: "name-985")
        let view = CareManagement.toFallbackAssessmentMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toFallbackAssessmentMilestoneViews([item, item]).count == 2)
    }
}
