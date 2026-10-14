@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCappedReferenceRangeRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CappedReferenceRangeRecordStore = Labs.newMemoryCappedReferenceRangeRecordStore()
        let item = Labs.newCappedReferenceRangeRecord("code-746", title: "title-779")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
