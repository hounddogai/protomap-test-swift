@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCappedModalityBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CappedModalityBatchStore = Imaging.newMemoryCappedModalityBatchStore()
        let item = Imaging.newCappedModalityBatch("code-673", name: "name-866")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
