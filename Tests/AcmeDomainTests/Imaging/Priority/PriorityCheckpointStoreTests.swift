@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityCheckpointStore = Imaging.newMemoryPriorityCheckpointStore()
        let item = Imaging.newPriorityCheckpoint("code-815", label: "label-98")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
