@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPrimaryReferenceRangeScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PrimaryReferenceRangeScheduleStore = Labs.newMemoryPrimaryReferenceRangeScheduleStore()
        let item = Labs.newPrimaryReferenceRangeSchedule("code-926", title: "title-277")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
