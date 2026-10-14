@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryBatchedModalityMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.BatchedModalityMappingStore = Imaging.newMemoryBatchedModalityMappingStore()
        let item = Imaging.newBatchedModalityMapping("code-226", name: "name-48")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
