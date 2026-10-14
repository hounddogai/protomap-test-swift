@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingStatementTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newPendingStatementTarget("code-24", name: "name-439")
        let view = RevenueCycle.toPendingStatementTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toPendingStatementTargetViews([item, item]).count == 2)
    }
}
