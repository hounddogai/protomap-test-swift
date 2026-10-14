@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveRoundingMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAdaptiveRoundingMetric("code-839", title: "title-22")
        let view = ClinicalOps.toAdaptiveRoundingMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAdaptiveRoundingMetricViews([item, item]).count == 2)
    }
}
