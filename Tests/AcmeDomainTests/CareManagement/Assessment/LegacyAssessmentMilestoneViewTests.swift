@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyAssessmentMilestoneViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newLegacyAssessmentMilestone("code-329", name: "name-855")
        let view = CareManagement.toLegacyAssessmentMilestoneView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toLegacyAssessmentMilestoneViews([item, item]).count == 2)
    }
}
