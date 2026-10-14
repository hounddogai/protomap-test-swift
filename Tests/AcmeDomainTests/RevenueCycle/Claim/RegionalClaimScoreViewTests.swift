@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalClaimScoreViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newRegionalClaimScore("code-512", label: "label-534")
        let view = RevenueCycle.toRegionalClaimScoreView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toRegionalClaimScoreViews([item, item]).count == 2)
    }
}
