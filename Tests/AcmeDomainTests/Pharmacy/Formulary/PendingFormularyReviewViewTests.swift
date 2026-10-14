@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingFormularyReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPendingFormularyReview("code-328", name: "name-26")
        let view = Pharmacy.toPendingFormularyReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPendingFormularyReviewViews([item, item]).count == 2)
    }
}
