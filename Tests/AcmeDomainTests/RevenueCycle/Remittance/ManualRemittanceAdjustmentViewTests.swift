@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualRemittanceAdjustmentViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newManualRemittanceAdjustment("code-791", name: "name-210")
        let view = RevenueCycle.toManualRemittanceAdjustmentView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toManualRemittanceAdjustmentViews([item, item]).count == 2)
    }
}
