@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingResultMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newPendingResultMetric("code-165", label: "label-670")
        let view = Labs.toPendingResultMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toPendingResultMetricViews([item, item]).count == 2)
    }
}
