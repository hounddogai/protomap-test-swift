@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalInteractionAgreementViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newSeasonalInteractionAgreement("code-160", label: "label-493")
        let view = Pharmacy.toSeasonalInteractionAgreementView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toSeasonalInteractionAgreementViews([item, item]).count == 2)
    }
}
