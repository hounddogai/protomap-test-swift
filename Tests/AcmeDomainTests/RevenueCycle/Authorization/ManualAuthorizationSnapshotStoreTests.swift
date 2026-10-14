@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryManualAuthorizationSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ManualAuthorizationSnapshotStore = RevenueCycle.newMemoryManualAuthorizationSnapshotStore()
        let item = RevenueCycle.newManualAuthorizationSnapshot("code-152", title: "title-308")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
