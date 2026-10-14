@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryWeightedDenialGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.WeightedDenialGroupStore = RevenueCycle.newMemoryWeightedDenialGroupStore()
        let item = RevenueCycle.newWeightedDenialGroup("code-375", name: "name-345")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
