@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryBatchedInteractionBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.BatchedInteractionBudgetStore = Pharmacy.newMemoryBatchedInteractionBudgetStore()
        let item = Pharmacy.newBatchedInteractionBudget("code-181", title: "title-592")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
