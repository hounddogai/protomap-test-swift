@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialThresholdStore = RevenueCycle.newMemoryDenialThresholdStore()
        let item = RevenueCycle.newDenialThreshold("code-784", title: "title-165")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
