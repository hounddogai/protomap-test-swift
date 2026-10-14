@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLegacyClaimBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LegacyClaimBudgetStore = RevenueCycle.newMemoryLegacyClaimBudgetStore()
        let item = RevenueCycle.newLegacyClaimBudget("code-673", title: "title-936")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
