@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultLedgerStore = Labs.newMemoryResultLedgerStore()
        let item = Labs.newResultLedger("code-7", name: "name-119")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
