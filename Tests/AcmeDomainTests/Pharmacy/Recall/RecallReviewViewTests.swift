@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallReview("code-565", name: "name-767")
        let view = Pharmacy.toRecallReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallReviewViews([item, item]).count == 2)
    }
}
