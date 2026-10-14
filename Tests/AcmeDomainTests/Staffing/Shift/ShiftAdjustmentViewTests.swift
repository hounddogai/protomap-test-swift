@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newShiftAdjustment("code-40", label: "label-919")
        let view = Staffing.toShiftAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toShiftAdjustmentViews([item, item]).count == 2)
    }
}
