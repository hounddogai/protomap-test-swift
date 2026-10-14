@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newChargeBudget("code-436", name: "name-195")
        let view = RevenueCycle.toChargeBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toChargeBudgetViews([item, item]).count == 2)
    }
}
