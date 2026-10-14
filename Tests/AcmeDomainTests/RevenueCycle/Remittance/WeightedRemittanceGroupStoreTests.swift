@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryWeightedRemittanceGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.WeightedRemittanceGroupStore = RevenueCycle.newMemoryWeightedRemittanceGroupStore()
        let item = RevenueCycle.newWeightedRemittanceGroup("code-754", label: "label-619")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
