@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventorySnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newInventorySnapshot("code-311", label: "label-155")
        let view = Pharmacy.toInventorySnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toInventorySnapshotViews([item, item]).count == 2)
    }
}
