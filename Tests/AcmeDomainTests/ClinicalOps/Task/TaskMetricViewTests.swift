@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newTaskMetric("code-649", title: "title-522")
        let view = ClinicalOps.toTaskMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toTaskMetricViews([item, item]).count == 2)
    }
}
