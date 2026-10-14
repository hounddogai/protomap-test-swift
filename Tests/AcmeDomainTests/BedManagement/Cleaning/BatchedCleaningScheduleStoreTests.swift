@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryBatchedCleaningScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.BatchedCleaningScheduleStore = BedManagement.newMemoryBatchedCleaningScheduleStore()
        let item = BedManagement.newBatchedCleaningSchedule("code-936", label: "label-121")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
