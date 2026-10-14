@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationMetric("code-432", name: "name-9")
        let view = BedManagement.toIsolationMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationMetricViews([item, item]).count == 2)
    }
}
