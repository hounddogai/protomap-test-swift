@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryManualPriorityBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ManualPriorityBudgetStore = Imaging.newMemoryManualPriorityBudgetStore()
        let item = Imaging.newManualPriorityBudget("code-155", title: "title-14")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
