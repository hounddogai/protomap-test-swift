@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newShiftTier("code-1", name: "name-169")
        let view = Staffing.toShiftTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toShiftTierViews([item, item]).count == 2)
    }
}
