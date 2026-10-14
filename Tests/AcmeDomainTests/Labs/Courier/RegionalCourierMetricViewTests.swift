@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalCourierMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRegionalCourierMetric("code-953", label: "label-796")
        let view = Labs.toRegionalCourierMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRegionalCourierMetricViews([item, item]).count == 2)
    }
}
