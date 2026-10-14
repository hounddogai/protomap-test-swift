@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedStatementBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedStatementBudgetStore = RevenueCycle.newMemoryBatchedStatementBudgetStore()
        let item = RevenueCycle.newBatchedStatementBudget("code-831", name: "name-254")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
