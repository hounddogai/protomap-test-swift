@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackAssessmentAssignmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newFallbackAssessmentAssignment("code-771", title: "title-84")
        let view = CareManagement.toFallbackAssessmentAssignmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toFallbackAssessmentAssignmentViews([item, item]).count == 2)
    }
}
