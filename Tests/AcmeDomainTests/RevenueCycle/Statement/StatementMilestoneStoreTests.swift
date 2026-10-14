@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStatementMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StatementMilestoneStore = RevenueCycle.newMemoryStatementMilestoneStore()
        let item = RevenueCycle.newStatementMilestone("code-993", name: "name-227")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
