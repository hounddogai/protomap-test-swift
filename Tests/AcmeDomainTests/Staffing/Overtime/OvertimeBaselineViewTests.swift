@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimeBaseline("code-978", title: "title-41")
        let view = Staffing.toOvertimeBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimeBaselineViews([item, item]).count == 2)
    }
}
