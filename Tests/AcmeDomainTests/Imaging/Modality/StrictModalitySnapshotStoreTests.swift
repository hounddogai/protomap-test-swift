@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStrictModalitySnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StrictModalitySnapshotStore = Imaging.newMemoryStrictModalitySnapshotStore()
        let item = Imaging.newStrictModalitySnapshot("code-359", label: "label-371")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
