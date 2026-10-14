@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newChargeEstimate("code-146", name: "name-865")
        let view = RevenueCycle.toChargeEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toChargeEstimateViews([item, item]).count == 2)
    }
}
