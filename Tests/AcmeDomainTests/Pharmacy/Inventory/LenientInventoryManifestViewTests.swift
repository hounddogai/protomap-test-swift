@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInventoryManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLenientInventoryManifest("code-323", title: "title-943")
        let view = Pharmacy.toLenientInventoryManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLenientInventoryManifestViews([item, item]).count == 2)
    }
}
