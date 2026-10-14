@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedFormularySnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newCappedFormularySnapshot("code-799", name: "name-316")
        let view = Pharmacy.toCappedFormularySnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toCappedFormularySnapshotViews([item, item]).count == 2)
    }
}
