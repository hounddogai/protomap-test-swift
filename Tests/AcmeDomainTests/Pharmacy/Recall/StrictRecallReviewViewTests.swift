@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictRecallReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newStrictRecallReview("code-784", label: "label-77")
        let view = Pharmacy.toStrictRecallReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toStrictRecallReviewViews([item, item]).count == 2)
    }
}
