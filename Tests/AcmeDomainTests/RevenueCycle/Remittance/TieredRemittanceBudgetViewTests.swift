@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredRemittanceBudgetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newTieredRemittanceBudget("code-90", name: "name-385")
        let view = RevenueCycle.toTieredRemittanceBudgetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toTieredRemittanceBudgetViews([item, item]).count == 2)
    }
}
