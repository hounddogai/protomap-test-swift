@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyFormularySnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newLegacyFormularySnapshot("code-207", title: "title-928")
        let view = Pharmacy.toLegacyFormularySnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toLegacyFormularySnapshotViews([item, item]).count == 2)
    }
}
