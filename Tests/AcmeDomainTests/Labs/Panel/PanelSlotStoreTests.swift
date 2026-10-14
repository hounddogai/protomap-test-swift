@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelSlotStore = Labs.newMemoryPanelSlotStore()
        let item = Labs.newPanelSlot("code-720", label: "label-278")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
