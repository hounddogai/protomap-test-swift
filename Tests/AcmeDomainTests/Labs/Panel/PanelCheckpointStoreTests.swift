@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelCheckpointStore = Labs.newMemoryPanelCheckpointStore()
        let item = Labs.newPanelCheckpoint("code-925", label: "label-121")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
