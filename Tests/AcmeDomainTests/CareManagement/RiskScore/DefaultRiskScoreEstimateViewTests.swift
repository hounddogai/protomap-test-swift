@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultRiskScoreEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newDefaultRiskScoreEstimate("code-451", label: "label-18")
        let view = CareManagement.toDefaultRiskScoreEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toDefaultRiskScoreEstimateViews([item, item]).count == 2)
    }
}
