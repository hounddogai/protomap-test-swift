@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStrictReadSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StrictReadSnapshotStore = Imaging.newMemoryStrictReadSnapshotStore()
        let item = Imaging.newStrictReadSnapshot("code-36", title: "title-302")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
