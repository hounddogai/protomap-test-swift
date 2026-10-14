@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceThresholdStore = RevenueCycle.newMemoryRemittanceThresholdStore()
        let item = RevenueCycle.newRemittanceThreshold("code-699", title: "title-19")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
