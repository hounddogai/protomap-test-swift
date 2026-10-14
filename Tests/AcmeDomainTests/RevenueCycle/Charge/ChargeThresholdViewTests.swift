@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newChargeThreshold("code-338", name: "name-617")
        let view = RevenueCycle.toChargeThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toChargeThresholdViews([item, item]).count == 2)
    }
}
