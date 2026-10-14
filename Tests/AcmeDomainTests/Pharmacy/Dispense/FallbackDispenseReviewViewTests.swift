@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackDispenseReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newFallbackDispenseReview("code-425", title: "title-94")
        let view = Pharmacy.toFallbackDispenseReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toFallbackDispenseReviewViews([item, item]).count == 2)
    }
}
