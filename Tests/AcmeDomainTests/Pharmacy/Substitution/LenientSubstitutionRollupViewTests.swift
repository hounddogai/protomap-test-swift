@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientSubstitutionRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLenientSubstitutionRollup("code-6", label: "label-469")
        let view = Pharmacy.toLenientSubstitutionRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLenientSubstitutionRollupViews([item, item]).count == 2)
    }
}
