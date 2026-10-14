@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredSubstitutionProfileViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newTieredSubstitutionProfile("code-853", label: "label-811")
        let view = Pharmacy.toTieredSubstitutionProfileView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toTieredSubstitutionProfileViews([item, item]).count == 2)
    }
}
