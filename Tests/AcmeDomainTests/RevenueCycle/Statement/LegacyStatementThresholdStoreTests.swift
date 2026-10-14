@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLegacyStatementThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LegacyStatementThresholdStore = RevenueCycle.newMemoryLegacyStatementThresholdStore()
        let item = RevenueCycle.newLegacyStatementThreshold("code-256", label: "label-846")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
