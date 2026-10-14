@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInteractionClaim("code-274", title: "title-915")
        let view = Pharmacy.toInteractionClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInteractionClaimViews([item, item]).count == 2)
    }
}
