@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStatementBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StatementBundleStore = RevenueCycle.newMemoryStatementBundleStore()
        let item = RevenueCycle.newStatementBundle("code-12", name: "name-828")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
