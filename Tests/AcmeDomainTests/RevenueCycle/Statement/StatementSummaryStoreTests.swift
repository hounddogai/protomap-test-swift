@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStatementSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StatementSummaryStore = RevenueCycle.newMemoryStatementSummaryStore()
        let item = RevenueCycle.newStatementSummary("code-527", name: "name-595")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
