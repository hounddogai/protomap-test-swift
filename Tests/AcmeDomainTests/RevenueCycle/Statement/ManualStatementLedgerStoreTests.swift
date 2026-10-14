@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryManualStatementLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ManualStatementLedgerStore = RevenueCycle.newMemoryManualStatementLedgerStore()
        let item = RevenueCycle.newManualStatementLedger("code-1", name: "name-93")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
