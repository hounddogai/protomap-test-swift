@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultSubstitutionTierViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDefaultSubstitutionTier("code-76", name: "name-40")
        let view = Pharmacy.toDefaultSubstitutionTierView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDefaultSubstitutionTierViews([item, item]).count == 2)
    }
}
