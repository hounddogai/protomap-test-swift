@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryTieredChargeBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.TieredChargeBatchStore = RevenueCycle.newMemoryTieredChargeBatchStore()
        let item = RevenueCycle.newTieredChargeBatch("code-49", label: "label-899")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
