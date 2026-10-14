@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStatementPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StatementPlanStore = RevenueCycle.newMemoryStatementPlanStore()
        let item = RevenueCycle.newStatementPlan("code-415", name: "name-839")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
