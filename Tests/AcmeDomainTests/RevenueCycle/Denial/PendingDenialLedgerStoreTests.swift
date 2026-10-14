@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryPendingDenialLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.PendingDenialLedgerStore = RevenueCycle.newMemoryPendingDenialLedgerStore()
        let item = RevenueCycle.newPendingDenialLedger("code-755", title: "title-84")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
