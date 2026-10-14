@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredClaimReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newTieredClaimReview("code-522", label: "label-357")
        let view = RevenueCycle.toTieredClaimReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toTieredClaimReviewViews([item, item]).count == 2)
    }
}
