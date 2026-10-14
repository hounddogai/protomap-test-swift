@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualAlertMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newManualAlertMetric("code-174", label: "label-920")
        let view = ClinicalOps.toManualAlertMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toManualAlertMetricViews([item, item]).count == 2)
    }
}
