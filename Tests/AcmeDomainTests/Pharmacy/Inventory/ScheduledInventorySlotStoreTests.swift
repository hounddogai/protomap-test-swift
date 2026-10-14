@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryScheduledInventorySlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.ScheduledInventorySlotStore = Pharmacy.newMemoryScheduledInventorySlotStore()
        let item = Pharmacy.newScheduledInventorySlot("code-168", label: "label-800")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
