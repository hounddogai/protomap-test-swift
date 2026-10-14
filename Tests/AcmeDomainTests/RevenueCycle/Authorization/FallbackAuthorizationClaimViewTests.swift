@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackAuthorizationClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newFallbackAuthorizationClaim("code-37", title: "title-540")
        let view = RevenueCycle.toFallbackAuthorizationClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toFallbackAuthorizationClaimViews([item, item]).count == 2)
    }
}
