@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryTieredStudyBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.TieredStudyBatchStore = Imaging.newMemoryTieredStudyBatchStore()
        let item = Imaging.newTieredStudyBatch("code-623", name: "name-564")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
