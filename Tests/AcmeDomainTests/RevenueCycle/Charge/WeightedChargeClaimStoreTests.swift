@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryWeightedChargeClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.WeightedChargeClaimStore = RevenueCycle.newMemoryWeightedChargeClaimStore()
        let item = RevenueCycle.newWeightedChargeClaim("code-434", name: "name-934")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
