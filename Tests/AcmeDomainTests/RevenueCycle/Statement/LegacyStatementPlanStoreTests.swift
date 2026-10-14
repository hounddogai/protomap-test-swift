@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLegacyStatementPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LegacyStatementPlanStore = RevenueCycle.newMemoryLegacyStatementPlanStore()
        let item = RevenueCycle.newLegacyStatementPlan("code-271", label: "label-279")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
