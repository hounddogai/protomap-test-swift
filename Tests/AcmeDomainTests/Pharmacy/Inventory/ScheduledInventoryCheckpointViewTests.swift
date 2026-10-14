@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventoryCheckpointViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Pharmacy.newScheduledInventoryCheckpoint("code-346", label: "label-197")
        let view = Pharmacy.toScheduledInventoryCheckpointView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Pharmacy.toScheduledInventoryCheckpointViews([item, item]).count == 2)
    }
}
