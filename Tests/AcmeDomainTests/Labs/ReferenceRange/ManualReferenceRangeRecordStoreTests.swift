@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryManualReferenceRangeRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ManualReferenceRangeRecordStore = Labs.newMemoryManualReferenceRangeRecordStore()
        let item = Labs.newManualReferenceRangeRecord("code-389", label: "label-321")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
