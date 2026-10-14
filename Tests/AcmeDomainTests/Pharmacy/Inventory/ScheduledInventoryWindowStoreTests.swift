@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryScheduledInventoryWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.ScheduledInventoryWindowStore = Pharmacy.newMemoryScheduledInventoryWindowStore()
        let item = Pharmacy.newScheduledInventoryWindow("code-144", label: "label-343")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
