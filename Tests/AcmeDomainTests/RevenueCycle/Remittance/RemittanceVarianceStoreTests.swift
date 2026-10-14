@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceVarianceStore = RevenueCycle.newMemoryRemittanceVarianceStore()
        let item = RevenueCycle.newRemittanceVariance("code-20", name: "name-830")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
