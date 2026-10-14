@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelPlanStore = Labs.newMemoryPanelPlanStore()
        let item = Labs.newPanelPlan("code-923", title: "title-507")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
