@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCensusMetric("code-636", name: "name-935")
        let view = BedManagement.toCensusMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCensusMetricViews([item, item]).count == 2)
    }
}
