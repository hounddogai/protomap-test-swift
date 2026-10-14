@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimBudget("code-649", title: "title-636")
        let view = RevenueCycle.toClaimBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimBudgetViews([item, item]).count == 2)
    }
}
