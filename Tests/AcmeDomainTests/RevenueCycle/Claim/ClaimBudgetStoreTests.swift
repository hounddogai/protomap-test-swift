@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimBudgetStore = RevenueCycle.newMemoryClaimBudgetStore()
        let item = RevenueCycle.newClaimBudget("code-649", title: "title-636")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
