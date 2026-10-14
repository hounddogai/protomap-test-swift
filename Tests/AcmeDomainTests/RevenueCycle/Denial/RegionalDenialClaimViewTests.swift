@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalDenialClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRegionalDenialClaim("code-587", title: "title-845")
        let view = RevenueCycle.toRegionalDenialClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRegionalDenialClaimViews([item, item]).count == 2)
    }
}
