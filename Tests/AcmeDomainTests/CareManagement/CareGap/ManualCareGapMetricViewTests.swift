@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualCareGapMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newManualCareGapMetric("code-260", name: "name-483")
        let view = CareManagement.toManualCareGapMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toManualCareGapMetricViews([item, item]).count == 2)
    }
}
