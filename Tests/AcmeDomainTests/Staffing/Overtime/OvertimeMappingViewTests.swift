@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeMappingViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimeMapping("code-596", title: "title-760")
        let view = Staffing.toOvertimeMappingView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimeMappingViews([item, item]).count == 2)
    }
}
