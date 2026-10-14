@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAdaptiveDenialVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AdaptiveDenialVarianceStore = RevenueCycle.newMemoryAdaptiveDenialVarianceStore()
        let item = RevenueCycle.newAdaptiveDenialVariance("code-915", label: "label-640")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
