@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newResultMetric("code-337", name: "name-188")
        let view = Labs.toResultMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toResultMetricViews([item, item]).count == 2)
    }
}
