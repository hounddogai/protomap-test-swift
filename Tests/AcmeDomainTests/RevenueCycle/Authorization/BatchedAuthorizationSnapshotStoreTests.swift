@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryBatchedAuthorizationSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.BatchedAuthorizationSnapshotStore = RevenueCycle.newMemoryBatchedAuthorizationSnapshotStore()
        let item = RevenueCycle.newBatchedAuthorizationSnapshot("code-442", title: "title-327")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
