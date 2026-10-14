@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelBatchStore = Labs.newMemoryPanelBatchStore()
        let item = Labs.newPanelBatch("code-235", label: "label-929")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
