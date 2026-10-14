@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySubstitutionLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SubstitutionLedgerStore = Pharmacy.newMemorySubstitutionLedgerStore()
        let item = Pharmacy.newSubstitutionLedger("code-465", label: "label-292")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
