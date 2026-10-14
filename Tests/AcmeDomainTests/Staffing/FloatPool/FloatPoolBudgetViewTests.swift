@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Staffing.newFloatPoolBudget("code-537", label: "label-573")
        let view = Staffing.toFloatPoolBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Staffing.toFloatPoolBudgetViews([item, item]).count == 2)
    }
}
