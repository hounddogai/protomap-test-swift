@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryTieredPanelPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.TieredPanelPlanStore = Labs.newMemoryTieredPanelPlanStore()
        let item = Labs.newTieredPanelPlan("code-319", title: "title-874")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
