@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryScheduledPanelAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ScheduledPanelAdjustmentStore = Labs.newMemoryScheduledPanelAdjustmentStore()
        let item = Labs.newScheduledPanelAdjustment("code-826", label: "label-526")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
