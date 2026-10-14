@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceSnapshotStore = RevenueCycle.newMemoryRemittanceSnapshotStore()
        let item = RevenueCycle.newRemittanceSnapshot("code-65", name: "name-106")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
