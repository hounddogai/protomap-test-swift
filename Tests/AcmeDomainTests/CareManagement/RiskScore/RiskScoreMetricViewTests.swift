@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newRiskScoreMetric("code-164", name: "name-890")
        let view = CareManagement.toRiskScoreMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toRiskScoreMetricViews([item, item]).count == 2)
    }
}
