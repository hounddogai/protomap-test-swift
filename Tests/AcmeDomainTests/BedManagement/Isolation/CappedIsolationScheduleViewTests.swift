@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedIsolationScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newCappedIsolationSchedule("code-457", name: "name-113")
        let view = BedManagement.toCappedIsolationScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toCappedIsolationScheduleViews([item, item]).count == 2)
    }
}
