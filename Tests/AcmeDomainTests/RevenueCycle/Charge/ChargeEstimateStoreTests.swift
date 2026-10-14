@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeEstimateStore = RevenueCycle.newMemoryChargeEstimateStore()
        let item = RevenueCycle.newChargeEstimate("code-146", name: "name-865")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
