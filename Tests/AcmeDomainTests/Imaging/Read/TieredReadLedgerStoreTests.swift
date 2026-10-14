@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryTieredReadLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.TieredReadLedgerStore = Imaging.newMemoryTieredReadLedgerStore()
        let item = Imaging.newTieredReadLedger("code-13", name: "name-724")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
