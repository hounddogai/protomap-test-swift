@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedCleaningMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newWeightedCleaningMetric("code-981", name: "name-656")
        let view = BedManagement.toWeightedCleaningMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toWeightedCleaningMetricViews([item, item]).count == 2)
    }
}
