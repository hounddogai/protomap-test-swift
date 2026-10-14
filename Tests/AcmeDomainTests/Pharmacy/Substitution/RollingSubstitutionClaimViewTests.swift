@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingSubstitutionClaimViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newRollingSubstitutionClaim("code-745", title: "title-293")
        let view = Pharmacy.toRollingSubstitutionClaimView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toRollingSubstitutionClaimViews([item, item]).count == 2)
    }
}
