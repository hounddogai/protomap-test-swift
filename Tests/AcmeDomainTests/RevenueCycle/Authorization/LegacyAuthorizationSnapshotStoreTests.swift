@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLegacyAuthorizationSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LegacyAuthorizationSnapshotStore = RevenueCycle.newMemoryLegacyAuthorizationSnapshotStore()
        let item = RevenueCycle.newLegacyAuthorizationSnapshot("code-640", label: "label-117")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
