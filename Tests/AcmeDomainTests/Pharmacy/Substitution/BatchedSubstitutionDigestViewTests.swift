@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedSubstitutionDigestViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newBatchedSubstitutionDigest("code-767", title: "title-738")
        let view = Pharmacy.toBatchedSubstitutionDigestView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toBatchedSubstitutionDigestViews([item, item]).count == 2)
    }
}
