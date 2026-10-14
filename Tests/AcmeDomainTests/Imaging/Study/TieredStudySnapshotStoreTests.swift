@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryTieredStudySnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.TieredStudySnapshotStore = Imaging.newMemoryTieredStudySnapshotStore()
        let item = Imaging.newTieredStudySnapshot("code-114", title: "title-985")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
