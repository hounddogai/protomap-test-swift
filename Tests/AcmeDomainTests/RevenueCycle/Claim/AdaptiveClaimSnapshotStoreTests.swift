@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAdaptiveClaimSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AdaptiveClaimSnapshotStore = RevenueCycle.newMemoryAdaptiveClaimSnapshotStore()
        let item = RevenueCycle.newAdaptiveClaimSnapshot("code-432", name: "name-739")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
