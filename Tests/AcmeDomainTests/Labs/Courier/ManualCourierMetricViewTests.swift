@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualCourierMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newManualCourierMetric("code-714", title: "title-625")
        let view = Labs.toManualCourierMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toManualCourierMetricViews([item, item]).count == 2)
    }
}
