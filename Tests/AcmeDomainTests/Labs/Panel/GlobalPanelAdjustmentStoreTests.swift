@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryGlobalPanelAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.GlobalPanelAdjustmentStore = Labs.newMemoryGlobalPanelAdjustmentStore()
        let item = Labs.newGlobalPanelAdjustment("code-908", title: "title-873")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
