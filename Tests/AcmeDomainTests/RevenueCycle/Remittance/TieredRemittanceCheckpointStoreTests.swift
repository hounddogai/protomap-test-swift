@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryTieredRemittanceCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.TieredRemittanceCheckpointStore = RevenueCycle.newMemoryTieredRemittanceCheckpointStore()
        let item = RevenueCycle.newTieredRemittanceCheckpoint("code-964", name: "name-292")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
