@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedCourierMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCappedCourierMetric("code-658", name: "name-302")
        let view = Labs.toCappedCourierMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCappedCourierMetricViews([item, item]).count == 2)
    }
}
