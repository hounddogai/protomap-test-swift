@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadLedgerStore = Imaging.newMemoryReadLedgerStore()
        let item = Imaging.newReadLedger("code-430", title: "title-902")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
