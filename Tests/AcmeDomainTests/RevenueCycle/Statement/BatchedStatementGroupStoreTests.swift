@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedStatementGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedStatementGroupStore = RevenueCycle.newMemoryBatchedStatementGroupStore()
        let item = RevenueCycle.newBatchedStatementGroup("code-987", title: "title-697")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
