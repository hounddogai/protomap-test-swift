@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingShiftNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newRollingShiftNotice("code-867", label: "label-426")
        let view = Staffing.toRollingShiftNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toRollingShiftNoticeViews([item, item]).count == 2)
    }
}
