@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryFallbackReferenceRangeBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.FallbackReferenceRangeBatchStore = Labs.newMemoryFallbackReferenceRangeBatchStore()
        let item = Labs.newFallbackReferenceRangeBatch("code-655", title: "title-240")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
