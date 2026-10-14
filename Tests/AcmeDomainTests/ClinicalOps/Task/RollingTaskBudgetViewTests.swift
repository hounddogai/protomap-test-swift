@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingTaskBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newRollingTaskBudget("code-956", name: "name-650")
        let view = ClinicalOps.toRollingTaskBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toRollingTaskBudgetViews([item, item]).count == 2)
    }
}
