@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferSlotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferSlot("code-711", title: "title-657")
        let view = BedManagement.toTransferSlotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferSlotViews([item, item]).count == 2)
    }
}
