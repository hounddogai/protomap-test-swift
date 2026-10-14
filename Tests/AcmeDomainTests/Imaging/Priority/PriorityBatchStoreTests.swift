@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityBatchStore = Imaging.newMemoryPriorityBatchStore()
        let item = Imaging.newPriorityBatch("code-87", label: "label-118")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
