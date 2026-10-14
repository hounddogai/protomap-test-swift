@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedAssessmentEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newBatchedAssessmentEstimate("code-848", label: "label-821")
        let view = CareManagement.toBatchedAssessmentEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toBatchedAssessmentEstimateViews([item, item]).count == 2)
    }
}
