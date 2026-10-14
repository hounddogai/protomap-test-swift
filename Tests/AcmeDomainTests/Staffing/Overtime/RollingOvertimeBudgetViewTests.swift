@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingOvertimeBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newRollingOvertimeBudget("code-87", title: "title-275")
        let view = Staffing.toRollingOvertimeBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toRollingOvertimeBudgetViews([item, item]).count == 2)
    }
}
