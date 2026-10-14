@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newTransferSchedule("code-679", name: "name-625")
        let view = BedManagement.toTransferScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toTransferScheduleViews([item, item]).count == 2)
    }
}
