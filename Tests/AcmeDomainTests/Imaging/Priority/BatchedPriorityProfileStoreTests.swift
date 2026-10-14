@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryBatchedPriorityProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.BatchedPriorityProfileStore = Imaging.newMemoryBatchedPriorityProfileStore()
        let item = Imaging.newBatchedPriorityProfile("code-296", title: "title-995")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
