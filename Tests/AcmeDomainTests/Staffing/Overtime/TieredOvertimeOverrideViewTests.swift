@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredOvertimeOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newTieredOvertimeOverride("code-982", name: "name-735")
        let view = Staffing.toTieredOvertimeOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toTieredOvertimeOverrideViews([item, item]).count == 2)
    }
}
