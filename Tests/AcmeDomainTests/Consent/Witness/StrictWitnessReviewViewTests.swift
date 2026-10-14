@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictWitnessReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Consent.newStrictWitnessReview("code-976", label: "label-764")
        let view = Consent.toStrictWitnessReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Consent.toStrictWitnessReviewViews([item, item]).count == 2)
    }
}
