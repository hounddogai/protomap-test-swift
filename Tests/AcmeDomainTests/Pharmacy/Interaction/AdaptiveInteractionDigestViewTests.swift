@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveInteractionDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newAdaptiveInteractionDigest("code-629", label: "label-67")
        let view = Pharmacy.toAdaptiveInteractionDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toAdaptiveInteractionDigestViews([item, item]).count == 2)
    }
}
