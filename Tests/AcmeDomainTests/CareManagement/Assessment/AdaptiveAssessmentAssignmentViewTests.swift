@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveAssessmentAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAdaptiveAssessmentAssignment("code-586", title: "title-500")
        let view = CareManagement.toAdaptiveAssessmentAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAdaptiveAssessmentAssignmentViews([item, item]).count == 2)
    }
}
