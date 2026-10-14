@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventoryManifest("code-453", title: "title-430")
        let view = Pharmacy.toInventoryManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventoryManifestViews([item, item]).count == 2)
    }
}
