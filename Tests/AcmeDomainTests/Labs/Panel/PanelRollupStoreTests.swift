@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelRollupStore = Labs.newMemoryPanelRollupStore()
        let item = Labs.newPanelRollup("code-767", title: "title-789")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
