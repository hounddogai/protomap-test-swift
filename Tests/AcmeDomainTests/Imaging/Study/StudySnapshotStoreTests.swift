@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudySnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudySnapshotStore = Imaging.newMemoryStudySnapshotStore()
        let item = Imaging.newStudySnapshot("code-138", name: "name-395")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
