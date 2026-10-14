@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newOvertimeBudget("code-595", name: "name-692")
        let view = Staffing.toOvertimeBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toOvertimeBudgetViews([item, item]).count == 2)
    }
}
