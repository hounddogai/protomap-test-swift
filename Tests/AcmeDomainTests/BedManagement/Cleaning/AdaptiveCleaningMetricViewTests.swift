@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCleaningMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newAdaptiveCleaningMetric("code-120", name: "name-750")
        let view = BedManagement.toAdaptiveCleaningMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toAdaptiveCleaningMetricViews([item, item]).count == 2)
    }
}
