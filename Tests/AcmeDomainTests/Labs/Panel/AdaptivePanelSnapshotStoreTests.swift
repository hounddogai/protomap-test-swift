@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAdaptivePanelSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AdaptivePanelSnapshotStore = Labs.newMemoryAdaptivePanelSnapshotStore()
        let item = Labs.newAdaptivePanelSnapshot("code-155", label: "label-152")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
