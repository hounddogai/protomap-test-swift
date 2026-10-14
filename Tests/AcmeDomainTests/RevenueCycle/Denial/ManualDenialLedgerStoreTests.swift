@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryManualDenialLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ManualDenialLedgerStore = RevenueCycle.newMemoryManualDenialLedgerStore()
        let item = RevenueCycle.newManualDenialLedger("code-602", name: "name-550")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
