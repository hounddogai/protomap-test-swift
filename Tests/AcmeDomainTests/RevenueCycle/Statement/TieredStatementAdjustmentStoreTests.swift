@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryTieredStatementAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.TieredStatementAdjustmentStore = RevenueCycle.newMemoryTieredStatementAdjustmentStore()
        let item = RevenueCycle.newTieredStatementAdjustment("code-763", label: "label-449")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
