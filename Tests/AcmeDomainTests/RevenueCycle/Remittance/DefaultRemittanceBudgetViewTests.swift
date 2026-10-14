@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultRemittanceBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newDefaultRemittanceBudget("code-756", title: "title-169")
        let view = RevenueCycle.toDefaultRemittanceBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toDefaultRemittanceBudgetViews([item, item]).count == 2)
    }
}
