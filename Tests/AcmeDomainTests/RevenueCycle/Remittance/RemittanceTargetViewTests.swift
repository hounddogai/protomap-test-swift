@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceTargetViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRemittanceTarget("code-417", label: "label-79")
        let view = RevenueCycle.toRemittanceTargetView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRemittanceTargetViews([item, item]).count == 2)
    }
}
