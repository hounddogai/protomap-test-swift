@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStatementMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StatementMetricStore = RevenueCycle.newMemoryStatementMetricStore()
        let item = RevenueCycle.newStatementMetric("code-19", name: "name-405")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
