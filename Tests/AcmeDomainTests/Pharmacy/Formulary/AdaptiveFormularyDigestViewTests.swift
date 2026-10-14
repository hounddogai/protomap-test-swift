@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveFormularyDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newAdaptiveFormularyDigest("code-596", label: "label-839")
        let view = Pharmacy.toAdaptiveFormularyDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toAdaptiveFormularyDigestViews([item, item]).count == 2)
    }
}
