@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentSummaryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newAssessmentSummary("code-34", label: "label-574")
        let view = CareManagement.toAssessmentSummaryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toAssessmentSummaryViews([item, item]).count == 2)
    }
}
