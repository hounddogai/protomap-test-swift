@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingConsentFormReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRollingConsentFormReview("code-581", title: "title-665")
        let view = Consent.toRollingConsentFormReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRollingConsentFormReviewViews([item, item]).count == 2)
    }
}
