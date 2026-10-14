@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackCensusMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newFallbackCensusMetric("code-812", name: "name-969")
        let view = BedManagement.toFallbackCensusMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toFallbackCensusMetricViews([item, item]).count == 2)
    }
}
