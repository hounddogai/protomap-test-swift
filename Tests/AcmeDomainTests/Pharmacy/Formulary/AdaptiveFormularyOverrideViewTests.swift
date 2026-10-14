@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveFormularyOverrideViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newAdaptiveFormularyOverride("code-274", label: "label-825")
        let view = Pharmacy.toAdaptiveFormularyOverrideView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toAdaptiveFormularyOverrideViews([item, item]).count == 2)
    }
}
