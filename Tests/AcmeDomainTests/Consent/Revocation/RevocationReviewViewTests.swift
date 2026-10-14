@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRevocationReview("code-941", title: "title-478")
        let view = Consent.toRevocationReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRevocationReviewViews([item, item]).count == 2)
    }
}
