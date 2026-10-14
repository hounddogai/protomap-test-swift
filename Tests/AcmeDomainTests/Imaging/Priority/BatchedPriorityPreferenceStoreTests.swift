@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryBatchedPriorityPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.BatchedPriorityPreferenceStore = Imaging.newMemoryBatchedPriorityPreferenceStore()
        let item = Imaging.newBatchedPriorityPreference("code-507", name: "name-952")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
