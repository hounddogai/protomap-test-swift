@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPendingRecallLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PendingRecallLedgerStore = Pharmacy.newMemoryPendingRecallLedgerStore()
        let item = Pharmacy.newPendingRecallLedger("code-610", label: "label-562")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
