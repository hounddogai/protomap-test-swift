@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryScheduledAuthorizationSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ScheduledAuthorizationSnapshotStore = RevenueCycle.newMemoryScheduledAuthorizationSnapshotStore()
        let item = RevenueCycle.newScheduledAuthorizationSnapshot("code-854", title: "title-337")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
