@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryTieredRemittanceAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.TieredRemittanceAdjustmentStore = RevenueCycle.newMemoryTieredRemittanceAdjustmentStore()
        let item = RevenueCycle.newTieredRemittanceAdjustment("code-386", name: "name-375")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
