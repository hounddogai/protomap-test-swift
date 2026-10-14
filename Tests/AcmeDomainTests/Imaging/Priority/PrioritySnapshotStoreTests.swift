@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPrioritySnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PrioritySnapshotStore = Imaging.newMemoryPrioritySnapshotStore()
        let item = Imaging.newPrioritySnapshot("code-229", label: "label-826")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
