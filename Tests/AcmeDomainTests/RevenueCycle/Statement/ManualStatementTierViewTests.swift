@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualStatementTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newManualStatementTier("code-259", label: "label-411")
        let view = RevenueCycle.toManualStatementTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toManualStatementTierViews([item, item]).count == 2)
    }
}
