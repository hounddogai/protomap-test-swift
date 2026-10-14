@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalFormularyReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newSeasonalFormularyReview("code-466", title: "title-524")
        let view = Pharmacy.toSeasonalFormularyReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toSeasonalFormularyReviewViews([item, item]).count == 2)
    }
}
