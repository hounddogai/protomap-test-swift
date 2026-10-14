@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryAlertMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newPrimaryAlertMetric("code-60", title: "title-982")
        let view = ClinicalOps.toPrimaryAlertMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toPrimaryAlertMetricViews([item, item]).count == 2)
    }
}
