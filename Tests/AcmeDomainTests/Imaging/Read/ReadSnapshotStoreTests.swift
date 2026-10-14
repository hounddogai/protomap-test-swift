@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadSnapshotStore = Imaging.newMemoryReadSnapshotStore()
        let item = Imaging.newReadSnapshot("code-276", title: "title-992")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
