@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolNoticeViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFloatPoolNotice("code-434", title: "title-501")
        let view = Staffing.toFloatPoolNoticeView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFloatPoolNoticeViews([item, item]).count == 2)
    }
}
