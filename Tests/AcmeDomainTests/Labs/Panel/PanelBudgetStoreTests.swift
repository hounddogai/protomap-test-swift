@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelBudgetStore = Labs.newMemoryPanelBudgetStore()
        let item = Labs.newPanelBudget("code-86", title: "title-572")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
