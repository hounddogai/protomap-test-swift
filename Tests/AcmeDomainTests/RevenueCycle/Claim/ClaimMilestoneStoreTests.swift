@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimMilestoneStore = RevenueCycle.newMemoryClaimMilestoneStore()
        let item = RevenueCycle.newClaimMilestone("code-997", name: "name-250")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
