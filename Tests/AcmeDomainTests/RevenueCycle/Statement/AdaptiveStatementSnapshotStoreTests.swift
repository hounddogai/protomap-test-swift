@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAdaptiveStatementSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AdaptiveStatementSnapshotStore = RevenueCycle.newMemoryAdaptiveStatementSnapshotStore()
        let item = RevenueCycle.newAdaptiveStatementSnapshot("code-144", name: "name-289")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
