@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledDenialClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newScheduledDenialClaim("code-189", name: "name-66")
        let view = RevenueCycle.toScheduledDenialClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toScheduledDenialClaimViews([item, item]).count == 2)
    }
}
