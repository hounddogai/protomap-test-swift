@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAdaptiveStatementThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AdaptiveStatementThresholdStore = RevenueCycle.newMemoryAdaptiveStatementThresholdStore()
        let item = RevenueCycle.newAdaptiveStatementThreshold("code-270", label: "label-70")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
