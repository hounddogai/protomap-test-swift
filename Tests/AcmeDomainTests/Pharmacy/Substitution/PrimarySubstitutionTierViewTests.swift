@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimarySubstitutionTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPrimarySubstitutionTier("code-420", label: "label-366")
        let view = Pharmacy.toPrimarySubstitutionTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPrimarySubstitutionTierViews([item, item]).count == 2)
    }
}
