@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStatementBudget("code-697", title: "title-84")
        let view = RevenueCycle.toStatementBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStatementBudgetViews([item, item]).count == 2)
    }
}
