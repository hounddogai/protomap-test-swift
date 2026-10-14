@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryFallbackResultLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.FallbackResultLedgerStore = Labs.newMemoryFallbackResultLedgerStore()
        let item = Labs.newFallbackResultLedger("code-477", name: "name-126")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
