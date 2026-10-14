@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedDispenseReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newCappedDispenseReview("code-411", label: "label-346")
        let view = Pharmacy.toCappedDispenseReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toCappedDispenseReviewViews([item, item]).count == 2)
    }
}
