@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveShiftNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newAdaptiveShiftNotice("code-810", title: "title-996")
        let view = Staffing.toAdaptiveShiftNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toAdaptiveShiftNoticeViews([item, item]).count == 2)
    }
}
