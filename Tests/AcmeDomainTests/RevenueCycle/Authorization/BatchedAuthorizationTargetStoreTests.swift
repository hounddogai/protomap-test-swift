@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedAuthorizationTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedAuthorizationTargetStore = RevenueCycle.newMemoryBatchedAuthorizationTargetStore()
        let item = RevenueCycle.newBatchedAuthorizationTarget("code-359", name: "name-295")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
