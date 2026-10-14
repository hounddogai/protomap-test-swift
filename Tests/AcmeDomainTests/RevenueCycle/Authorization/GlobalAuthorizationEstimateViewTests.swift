@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalAuthorizationEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newGlobalAuthorizationEstimate("code-63", name: "name-32")
        let view = RevenueCycle.toGlobalAuthorizationEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toGlobalAuthorizationEstimateViews([item, item]).count == 2)
    }
}
