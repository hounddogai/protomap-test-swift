@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedAuthorizationBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedAuthorizationBaselineStore = RevenueCycle.newMemoryBatchedAuthorizationBaselineStore()
        let item = RevenueCycle.newBatchedAuthorizationBaseline("code-856", name: "name-455")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
