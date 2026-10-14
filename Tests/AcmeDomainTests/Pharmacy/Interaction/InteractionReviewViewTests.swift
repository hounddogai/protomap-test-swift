@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInteractionReview("code-84", label: "label-306")
        let view = Pharmacy.toInteractionReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInteractionReviewViews([item, item]).count == 2)
    }
}
