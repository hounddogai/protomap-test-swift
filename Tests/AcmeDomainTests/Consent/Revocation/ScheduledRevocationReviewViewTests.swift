@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledRevocationReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newScheduledRevocationReview("code-100", name: "name-528")
        let view = Consent.toScheduledRevocationReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toScheduledRevocationReviewViews([item, item]).count == 2)
    }
}
