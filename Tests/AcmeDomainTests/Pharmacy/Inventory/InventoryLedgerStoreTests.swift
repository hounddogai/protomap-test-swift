@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventoryLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventoryLedgerStore = Pharmacy.newMemoryInventoryLedgerStore()
        let item = Pharmacy.newInventoryLedger("code-578", label: "label-805")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
