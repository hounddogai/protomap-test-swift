@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = RevenueCycle.newDenialReview("code-660", name: "name-565")
        let view = RevenueCycle.toDenialReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(RevenueCycle.toDenialReviewViews([item, item]).count == 2)
    }
}
