@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingClaimOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRollingClaimOverride("code-822", title: "title-376")
        let view = RevenueCycle.toRollingClaimOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRollingClaimOverrideViews([item, item]).count == 2)
    }
}
