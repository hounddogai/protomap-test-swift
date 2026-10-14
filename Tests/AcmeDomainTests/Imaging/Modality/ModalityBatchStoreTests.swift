@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityBatchStore = Imaging.newMemoryModalityBatchStore()
        let item = Imaging.newModalityBatch("code-729", title: "title-399")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
