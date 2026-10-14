@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveStatementThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newAdaptiveStatementThreshold("code-270", label: "label-70")
        let view = RevenueCycle.toAdaptiveStatementThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toAdaptiveStatementThresholdViews([item, item]).count == 2)
    }
}
