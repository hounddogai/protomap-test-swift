@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInventorySnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newPrimaryInventorySnapshot("code-273", label: "label-670")
        let view = Pharmacy.toPrimaryInventorySnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toPrimaryInventorySnapshotViews([item, item]).count == 2)
    }
}
