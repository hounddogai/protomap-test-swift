@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimOverride("code-114", label: "label-974")
        let view = RevenueCycle.toClaimOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimOverrideViews([item, item]).count == 2)
    }
}
