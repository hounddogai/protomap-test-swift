@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalSubstitutionReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRegionalSubstitutionReview("code-821", name: "name-30")
        let view = Pharmacy.toRegionalSubstitutionReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRegionalSubstitutionReviewViews([item, item]).count == 2)
    }
}
