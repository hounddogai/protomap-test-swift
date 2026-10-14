@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialAdjustmentStore = RevenueCycle.newMemoryDenialAdjustmentStore()
        let item = RevenueCycle.newDenialAdjustment("code-839", name: "name-149")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
