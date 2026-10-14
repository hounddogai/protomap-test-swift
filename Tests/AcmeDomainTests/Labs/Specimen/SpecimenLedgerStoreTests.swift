@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenLedgerStore = Labs.newMemorySpecimenLedgerStore()
        let item = Labs.newSpecimenLedger("code-494", name: "name-12")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
