@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeVarianceStore = RevenueCycle.newMemoryChargeVarianceStore()
        let item = RevenueCycle.newChargeVariance("code-920", title: "title-76")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
