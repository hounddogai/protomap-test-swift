@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialSnapshotStore = RevenueCycle.newMemoryDenialSnapshotStore()
        let item = RevenueCycle.newDenialSnapshot("code-593", name: "name-395")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
