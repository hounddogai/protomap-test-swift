@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newWitnessReview("code-475", name: "name-907")
        let view = Consent.toWitnessReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toWitnessReviewViews([item, item]).count == 2)
    }
}
