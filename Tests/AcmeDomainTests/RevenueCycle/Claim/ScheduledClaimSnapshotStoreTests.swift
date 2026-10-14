@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryScheduledClaimSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ScheduledClaimSnapshotStore = RevenueCycle.newMemoryScheduledClaimSnapshotStore()
        let item = RevenueCycle.newScheduledClaimSnapshot("code-278", name: "name-28")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
