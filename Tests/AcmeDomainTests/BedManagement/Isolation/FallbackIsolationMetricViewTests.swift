@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackIsolationMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newFallbackIsolationMetric("code-725", title: "title-263")
        let view = BedManagement.toFallbackIsolationMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toFallbackIsolationMetricViews([item, item]).count == 2)
    }
}
