@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalClaimProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRegionalClaimProfile("code-247", title: "title-866")
        let view = RevenueCycle.toRegionalClaimProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRegionalClaimProfileViews([item, item]).count == 2)
    }
}
