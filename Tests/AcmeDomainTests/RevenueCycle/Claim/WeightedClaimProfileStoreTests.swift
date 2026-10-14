@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryWeightedClaimProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.WeightedClaimProfileStore = RevenueCycle.newMemoryWeightedClaimProfileStore()
        let item = RevenueCycle.newWeightedClaimProfile("code-147", label: "label-734")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
