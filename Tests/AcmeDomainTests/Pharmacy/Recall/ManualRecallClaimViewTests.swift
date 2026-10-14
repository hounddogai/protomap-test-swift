@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newManualRecallClaim("code-709", title: "title-443")
        let view = Pharmacy.toManualRecallClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toManualRecallClaimViews([item, item]).count == 2)
    }
}
