@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityBudgetStore = Imaging.newMemoryPriorityBudgetStore()
        let item = Imaging.newPriorityBudget("code-599", name: "name-371")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
