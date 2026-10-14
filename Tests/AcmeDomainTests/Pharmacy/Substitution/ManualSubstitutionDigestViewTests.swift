@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualSubstitutionDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newManualSubstitutionDigest("code-835", name: "name-699")
        let view = Pharmacy.toManualSubstitutionDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toManualSubstitutionDigestViews([item, item]).count == 2)
    }
}
