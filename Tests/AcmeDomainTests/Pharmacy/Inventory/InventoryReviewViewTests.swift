@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventoryReview("code-473", name: "name-750")
        let view = Pharmacy.toInventoryReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryReviewViews([item, item]).count == 2)
    }
}
