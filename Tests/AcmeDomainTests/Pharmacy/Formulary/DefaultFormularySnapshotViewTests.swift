@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultFormularySnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newDefaultFormularySnapshot("code-611", name: "name-681")
        let view = Pharmacy.toDefaultFormularySnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toDefaultFormularySnapshotViews([item, item]).count == 2)
    }
}
