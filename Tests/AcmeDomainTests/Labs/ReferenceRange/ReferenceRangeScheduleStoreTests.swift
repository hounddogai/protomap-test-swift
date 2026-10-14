@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeScheduleStore = Labs.newMemoryReferenceRangeScheduleStore()
        let item = Labs.newReferenceRangeSchedule("code-816", name: "name-3")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
