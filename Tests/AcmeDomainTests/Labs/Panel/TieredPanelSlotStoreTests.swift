@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryTieredPanelSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.TieredPanelSlotStore = Labs.newMemoryTieredPanelSlotStore()
        let item = Labs.newTieredPanelSlot("code-179", label: "label-5")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
