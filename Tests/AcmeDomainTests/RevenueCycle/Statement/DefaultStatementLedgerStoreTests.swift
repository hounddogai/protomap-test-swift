@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDefaultStatementLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DefaultStatementLedgerStore = RevenueCycle.newMemoryDefaultStatementLedgerStore()
        let item = RevenueCycle.newDefaultStatementLedger("code-262", title: "title-178")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
