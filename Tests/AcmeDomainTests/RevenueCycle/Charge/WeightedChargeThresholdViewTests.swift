@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedChargeThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newWeightedChargeThreshold("code-879", name: "name-110")
        let view = RevenueCycle.toWeightedChargeThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toWeightedChargeThresholdViews([item, item]).count == 2)
    }
}
