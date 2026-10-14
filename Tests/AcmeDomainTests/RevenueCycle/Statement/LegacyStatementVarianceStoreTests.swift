@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLegacyStatementVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LegacyStatementVarianceStore = RevenueCycle.newMemoryLegacyStatementVarianceStore()
        let item = RevenueCycle.newLegacyStatementVariance("code-873", label: "label-335")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
