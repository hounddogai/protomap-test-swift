@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventoryScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventoryScheduleStore = Pharmacy.newMemoryInventoryScheduleStore()
        let item = Pharmacy.newInventorySchedule("code-91", label: "label-479")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
