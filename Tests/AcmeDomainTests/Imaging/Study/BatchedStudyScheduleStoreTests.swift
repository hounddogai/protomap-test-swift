@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryBatchedStudyScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.BatchedStudyScheduleStore = Imaging.newMemoryBatchedStudyScheduleStore()
        let item = Imaging.newBatchedStudySchedule("code-151", name: "name-961")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
