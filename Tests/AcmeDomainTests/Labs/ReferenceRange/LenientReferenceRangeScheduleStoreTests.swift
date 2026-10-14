@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLenientReferenceRangeScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LenientReferenceRangeScheduleStore = Labs.newMemoryLenientReferenceRangeScheduleStore()
        let item = Labs.newLenientReferenceRangeSchedule("code-623", title: "title-501")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
