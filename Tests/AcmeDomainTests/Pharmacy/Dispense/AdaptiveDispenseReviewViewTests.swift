@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveDispenseReviewViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newAdaptiveDispenseReview("code-906", label: "label-529")
        let view = Pharmacy.toAdaptiveDispenseReviewView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toAdaptiveDispenseReviewViews([item, item]).count == 2)
    }
}
