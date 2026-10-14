@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimeAdjustment("code-541", label: "label-910")
        let view = Staffing.toOvertimeAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimeAdjustmentViews([item, item]).count == 2)
    }
}
