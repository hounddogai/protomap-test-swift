@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferCheckpoint("code-274", title: "title-261")
        let view = BedManagement.toTransferCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferCheckpointViews([item, item]).count == 2)
    }
}
