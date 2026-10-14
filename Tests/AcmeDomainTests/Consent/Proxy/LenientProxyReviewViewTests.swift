@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newLenientProxyReview("code-861", label: "label-575")
        let view = Consent.toLenientProxyReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toLenientProxyReviewViews([item, item]).count == 2)
    }
}
