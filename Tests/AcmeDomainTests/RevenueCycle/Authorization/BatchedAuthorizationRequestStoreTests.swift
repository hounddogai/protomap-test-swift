@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedAuthorizationRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedAuthorizationRequestStore = RevenueCycle.newMemoryBatchedAuthorizationRequestStore()
        let item = RevenueCycle.newBatchedAuthorizationRequest("code-395", label: "label-742")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
