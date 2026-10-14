@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newClaimReview("code-315", name: "name-840")
        let view = RevenueCycle.toClaimReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toClaimReviewViews([item, item]).count == 2)
    }
}
