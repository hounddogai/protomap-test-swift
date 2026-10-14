@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyOrderSetMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newLegacyOrderSetMetric("code-692", name: "name-378")
        let view = ClinicalOps.toLegacyOrderSetMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toLegacyOrderSetMetricViews([item, item]).count == 2)
    }
}
