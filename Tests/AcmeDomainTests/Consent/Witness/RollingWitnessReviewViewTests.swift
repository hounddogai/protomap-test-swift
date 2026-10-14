@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingWitnessReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newRollingWitnessReview("code-539", name: "name-746")
        let view = Consent.toRollingWitnessReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toRollingWitnessReviewViews([item, item]).count == 2)
    }
}
