@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveTransferMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newAdaptiveTransferMetric("code-100", title: "title-930")
        let view = BedManagement.toAdaptiveTransferMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toAdaptiveTransferMetricViews([item, item]).count == 2)
    }
}
