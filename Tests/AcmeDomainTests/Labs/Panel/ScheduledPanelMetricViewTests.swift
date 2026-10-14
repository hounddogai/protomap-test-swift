@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledPanelMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newScheduledPanelMetric("code-889", label: "label-548")
        let view = Labs.toScheduledPanelMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toScheduledPanelMetricViews([item, item]).count == 2)
    }
}
