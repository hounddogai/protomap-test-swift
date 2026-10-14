@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryTieredCareProtocolLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.TieredCareProtocolLedgerStore = Imaging.newMemoryTieredCareProtocolLedgerStore()
        let item = Imaging.newTieredCareProtocolLedger("code-185", name: "name-767")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
