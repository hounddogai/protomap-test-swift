@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictRemittanceEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newStrictRemittanceEstimate("code-850", name: "name-699")
        let view = RevenueCycle.toStrictRemittanceEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toStrictRemittanceEstimateViews([item, item]).count == 2)
    }
}
