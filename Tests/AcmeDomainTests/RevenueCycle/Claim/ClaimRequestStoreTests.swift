@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimRequestStore = RevenueCycle.newMemoryClaimRequestStore()
        let item = RevenueCycle.newClaimRequest("code-347", title: "title-417")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
