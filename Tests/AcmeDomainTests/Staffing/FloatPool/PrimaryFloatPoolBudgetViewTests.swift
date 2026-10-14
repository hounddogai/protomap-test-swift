@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryFloatPoolBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newPrimaryFloatPoolBudget("code-218", name: "name-570")
        let view = Staffing.toPrimaryFloatPoolBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toPrimaryFloatPoolBudgetViews([item, item]).count == 2)
    }
}
