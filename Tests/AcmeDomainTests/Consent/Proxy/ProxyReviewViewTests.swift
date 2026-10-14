@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newProxyReview("code-595", name: "name-867")
        let view = Consent.toProxyReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toProxyReviewViews([item, item]).count == 2)
    }
}
