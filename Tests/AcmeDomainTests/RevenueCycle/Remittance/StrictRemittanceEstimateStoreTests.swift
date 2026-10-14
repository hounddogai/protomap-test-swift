@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStrictRemittanceEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StrictRemittanceEstimateStore = RevenueCycle.newMemoryStrictRemittanceEstimateStore()
        let item = RevenueCycle.newStrictRemittanceEstimate("code-850", name: "name-699")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
