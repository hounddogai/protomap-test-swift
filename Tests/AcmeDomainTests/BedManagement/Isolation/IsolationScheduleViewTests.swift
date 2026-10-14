@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationScheduleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = BedManagement.newIsolationSchedule("code-299", title: "title-420")
        let view = BedManagement.toIsolationScheduleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(BedManagement.toIsolationScheduleViews([item, item]).count == 2)
    }
}
