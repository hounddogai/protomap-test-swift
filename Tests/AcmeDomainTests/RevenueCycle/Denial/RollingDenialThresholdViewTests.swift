@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingDenialThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRollingDenialThreshold("code-699", title: "title-610")
        let view = RevenueCycle.toRollingDenialThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRollingDenialThresholdViews([item, item]).count == 2)
    }
}
