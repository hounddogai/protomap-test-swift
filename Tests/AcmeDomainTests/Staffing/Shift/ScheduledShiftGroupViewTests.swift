@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledShiftGroupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newScheduledShiftGroup("code-449", label: "label-839")
        let view = Staffing.toScheduledShiftGroupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toScheduledShiftGroupViews([item, item]).count == 2)
    }
}
