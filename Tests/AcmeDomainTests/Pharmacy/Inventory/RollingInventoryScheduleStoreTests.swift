@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRollingInventoryScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RollingInventoryScheduleStore = Pharmacy.newMemoryRollingInventoryScheduleStore()
        let item = Pharmacy.newRollingInventorySchedule("code-599", label: "label-808")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
