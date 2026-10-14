@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStatementAdjustment("code-520", label: "label-769")
        let view = RevenueCycle.toStatementAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStatementAdjustmentViews([item, item]).count == 2)
    }
}
