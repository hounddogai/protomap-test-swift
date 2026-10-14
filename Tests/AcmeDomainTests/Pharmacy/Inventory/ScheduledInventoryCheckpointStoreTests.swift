@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryScheduledInventoryCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.ScheduledInventoryCheckpointStore = Pharmacy.newMemoryScheduledInventoryCheckpointStore()
        let item = Pharmacy.newScheduledInventoryCheckpoint("code-346", label: "label-197")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
