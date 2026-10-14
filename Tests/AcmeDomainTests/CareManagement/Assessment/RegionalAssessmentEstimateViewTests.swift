@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalAssessmentEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRegionalAssessmentEstimate("code-85", name: "name-45")
        let view = CareManagement.toRegionalAssessmentEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRegionalAssessmentEstimateViews([item, item]).count == 2)
    }
}
