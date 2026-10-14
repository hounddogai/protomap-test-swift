@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledTransferAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newScheduledTransferAdjustment("code-800", label: "label-761")
        let view = BedManagement.toScheduledTransferAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toScheduledTransferAdjustmentViews([item, item]).count == 2)
    }
}
