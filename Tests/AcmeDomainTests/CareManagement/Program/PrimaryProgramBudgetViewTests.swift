@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryProgramBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newPrimaryProgramBudget("code-96", label: "label-235")
        let view = CareManagement.toPrimaryProgramBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toPrimaryProgramBudgetViews([item, item]).count == 2)
    }
}
