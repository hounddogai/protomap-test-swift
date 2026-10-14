@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallLedgerStore = Pharmacy.newMemoryRecallLedgerStore()
        let item = Pharmacy.newRecallLedger("code-20", name: "name-519")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
