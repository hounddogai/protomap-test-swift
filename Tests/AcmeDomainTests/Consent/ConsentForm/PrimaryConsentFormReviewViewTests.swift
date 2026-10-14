@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryConsentFormReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newPrimaryConsentFormReview("code-466", title: "title-184")
        let view = Consent.toPrimaryConsentFormReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toPrimaryConsentFormReviewViews([item, item]).count == 2)
    }
}
