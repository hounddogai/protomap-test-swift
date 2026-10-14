@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyFormularyRollupViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLegacyFormularyRollup("code-934", label: "label-599")
        let view = Pharmacy.toLegacyFormularyRollupView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLegacyFormularyRollupViews([item, item]).count == 2)
    }
}
