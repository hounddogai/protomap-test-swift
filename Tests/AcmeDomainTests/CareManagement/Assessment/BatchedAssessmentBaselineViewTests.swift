@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedAssessmentBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newBatchedAssessmentBaseline("code-905", label: "label-343")
        let view = CareManagement.toBatchedAssessmentBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toBatchedAssessmentBaselineViews([item, item]).count == 2)
    }
}
