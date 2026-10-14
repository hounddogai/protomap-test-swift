@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = ClinicalOps.newAlertBudget("code-526", title: "title-353")
        let view = ClinicalOps.toAlertBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(ClinicalOps.toAlertBudgetViews([item, item]).count == 2)
    }
}
