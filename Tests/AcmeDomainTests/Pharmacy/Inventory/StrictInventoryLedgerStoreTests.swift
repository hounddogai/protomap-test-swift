@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryStrictInventoryLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.StrictInventoryLedgerStore = Pharmacy.newMemoryStrictInventoryLedgerStore()
        let item = Pharmacy.newStrictInventoryLedger("code-280", title: "title-512")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
