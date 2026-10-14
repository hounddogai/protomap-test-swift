@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newShiftNotice("code-15", label: "label-262")
        let view = Staffing.toShiftNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toShiftNoticeViews([item, item]).count == 2)
    }
}
