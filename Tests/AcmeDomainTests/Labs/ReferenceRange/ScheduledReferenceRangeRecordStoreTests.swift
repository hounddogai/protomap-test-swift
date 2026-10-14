@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryScheduledReferenceRangeRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ScheduledReferenceRangeRecordStore = Labs.newMemoryScheduledReferenceRangeRecordStore()
        let item = Labs.newScheduledReferenceRangeRecord("code-551", label: "label-90")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
