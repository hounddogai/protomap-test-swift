@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelRecordStore = Labs.newMemoryPanelRecordStore()
        let item = Labs.newPanelRecord("code-876", label: "label-584")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
