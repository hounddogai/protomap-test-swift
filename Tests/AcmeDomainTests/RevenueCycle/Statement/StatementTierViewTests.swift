@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStatementTier("code-897", name: "name-368")
        let view = RevenueCycle.toStatementTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStatementTierViews([item, item]).count == 2)
    }
}
