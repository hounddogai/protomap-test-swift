@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialVarianceStore = RevenueCycle.newMemoryDenialVarianceStore()
        let item = RevenueCycle.newDenialVariance("code-693", title: "title-563")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
