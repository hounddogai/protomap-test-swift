@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCappedPanelBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CappedPanelBudgetStore = Labs.newMemoryCappedPanelBudgetStore()
        let item = Labs.newCappedPanelBudget("code-425", title: "title-472")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
