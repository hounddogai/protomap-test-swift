@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStatementThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StatementThresholdStore = RevenueCycle.newMemoryStatementThresholdStore()
        let item = RevenueCycle.newStatementThreshold("code-371", title: "title-993")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
