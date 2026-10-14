@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRecallClaim("code-55", name: "name-771")
        let view = Pharmacy.toRecallClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRecallClaimViews([item, item]).count == 2)
    }
}
