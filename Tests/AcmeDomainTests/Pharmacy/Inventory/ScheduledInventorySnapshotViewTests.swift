@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventorySnapshotViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newScheduledInventorySnapshot("code-331", title: "title-204")
        let view = Pharmacy.toScheduledInventorySnapshotView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toScheduledInventorySnapshotViews([item, item]).count == 2)
    }
}
