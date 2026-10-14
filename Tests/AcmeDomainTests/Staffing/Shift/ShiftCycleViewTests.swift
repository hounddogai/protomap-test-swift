@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftCycleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newShiftCycle("code-669", name: "name-897")
        let view = Staffing.toShiftCycleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toShiftCycleViews([item, item]).count == 2)
    }
}
