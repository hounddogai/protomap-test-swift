@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeLedgerStore = RevenueCycle.newMemoryChargeLedgerStore()
        let item = RevenueCycle.newChargeLedger("code-393", title: "title-778")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
