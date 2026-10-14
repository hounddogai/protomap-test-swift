@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyCensusMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newLegacyCensusMetric("code-588", name: "name-939")
        let view = BedManagement.toLegacyCensusMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toLegacyCensusMetricViews([item, item]).count == 2)
    }
}
