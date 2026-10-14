@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryRegionalStudySnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.RegionalStudySnapshotStore = Imaging.newMemoryRegionalStudySnapshotStore()
        let item = Imaging.newRegionalStudySnapshot("code-193", name: "name-938")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
