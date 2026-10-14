@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityLedgerStore = Imaging.newMemoryModalityLedgerStore()
        let item = Imaging.newModalityLedger("code-654", name: "name-472")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
