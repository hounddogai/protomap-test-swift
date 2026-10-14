@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryWeightedChargePolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.WeightedChargePolicyStore = RevenueCycle.newMemoryWeightedChargePolicyStore()
        let item = RevenueCycle.newWeightedChargePolicy("code-50", label: "label-680")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
