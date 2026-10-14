@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackDispenseManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newFallbackDispenseManifest("code-969", name: "name-876")
        let view = Pharmacy.toFallbackDispenseManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toFallbackDispenseManifestViews([item, item]).count == 2)
    }
}
