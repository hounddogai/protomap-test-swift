@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStatementMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StatementMappingStore = RevenueCycle.newMemoryStatementMappingStore()
        let item = RevenueCycle.newStatementMapping("code-159", title: "title-945")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
