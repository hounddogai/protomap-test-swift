@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryWeightedClaimTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.WeightedClaimTemplateStore = RevenueCycle.newMemoryWeightedClaimTemplateStore()
        let item = RevenueCycle.newWeightedClaimTemplate("code-76", label: "label-394")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
