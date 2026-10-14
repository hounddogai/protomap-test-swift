@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryPendingChargeBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.PendingChargeBatchStore = RevenueCycle.newMemoryPendingChargeBatchStore()
        let item = RevenueCycle.newPendingChargeBatch("code-864", title: "title-214")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
