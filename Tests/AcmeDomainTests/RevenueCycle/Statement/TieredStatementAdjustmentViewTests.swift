@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredStatementAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newTieredStatementAdjustment("code-763", label: "label-449")
        let view = RevenueCycle.toTieredStatementAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toTieredStatementAdjustmentViews([item, item]).count == 2)
    }
}
