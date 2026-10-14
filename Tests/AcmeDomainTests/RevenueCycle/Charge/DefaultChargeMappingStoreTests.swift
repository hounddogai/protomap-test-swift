@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDefaultChargeMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DefaultChargeMappingStore = RevenueCycle.newMemoryDefaultChargeMappingStore()
        let item = RevenueCycle.newDefaultChargeMapping("code-504", label: "label-791")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
