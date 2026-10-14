@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryWeightedClaimGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.WeightedClaimGroupStore = RevenueCycle.newMemoryWeightedClaimGroupStore()
        let item = RevenueCycle.newWeightedClaimGroup("code-679", title: "title-200")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
