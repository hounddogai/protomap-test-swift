@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualInventoryManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newManualInventoryManifest("code-99", label: "label-824")
        let view = Pharmacy.toManualInventoryManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toManualInventoryManifestViews([item, item]).count == 2)
    }
}
