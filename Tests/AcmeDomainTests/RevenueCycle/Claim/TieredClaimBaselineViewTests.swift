@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredClaimBaselineViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newTieredClaimBaseline("code-732", label: "label-465")
        let view = RevenueCycle.toTieredClaimBaselineView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toTieredClaimBaselineViews([item, item]).count == 2)
    }
}
