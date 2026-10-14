@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimarySubstitutionBundleViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPrimarySubstitutionBundle("code-255", name: "name-95")
        let view = Pharmacy.toPrimarySubstitutionBundleView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPrimarySubstitutionBundleViews([item, item]).count == 2)
    }
}
