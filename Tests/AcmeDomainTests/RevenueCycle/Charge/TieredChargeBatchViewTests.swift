@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredChargeBatchViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newTieredChargeBatch("code-49", label: "label-899")
        let view = RevenueCycle.toTieredChargeBatchView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toTieredChargeBatchViews([item, item]).count == 2)
    }
}
