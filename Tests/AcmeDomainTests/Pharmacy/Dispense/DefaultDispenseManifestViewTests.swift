@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultDispenseManifestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDefaultDispenseManifest("code-815", title: "title-860")
        let view = Pharmacy.toDefaultDispenseManifestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDefaultDispenseManifestViews([item, item]).count == 2)
    }
}
