@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackTransferMetricViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newFallbackTransferMetric("code-389", label: "label-580")
        let view = BedManagement.toFallbackTransferMetricView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toFallbackTransferMetricViews([item, item]).count == 2)
    }
}
