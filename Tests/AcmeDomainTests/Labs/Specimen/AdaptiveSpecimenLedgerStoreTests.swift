@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAdaptiveSpecimenLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AdaptiveSpecimenLedgerStore = Labs.newMemoryAdaptiveSpecimenLedgerStore()
        let item = Labs.newAdaptiveSpecimenLedger("code-112", label: "label-452")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
