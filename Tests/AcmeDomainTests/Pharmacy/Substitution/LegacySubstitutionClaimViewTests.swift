@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacySubstitutionClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLegacySubstitutionClaim("code-189", title: "title-177")
        let view = Pharmacy.toLegacySubstitutionClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLegacySubstitutionClaimViews([item, item]).count == 2)
    }
}
