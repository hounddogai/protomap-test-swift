@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInventoryDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLenientInventoryDigest("code-369", label: "label-490")
        let view = Pharmacy.toLenientInventoryDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLenientInventoryDigestViews([item, item]).count == 2)
    }
}
