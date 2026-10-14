@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolLedgerStore = Imaging.newMemoryCareProtocolLedgerStore()
        let item = Imaging.newCareProtocolLedger("code-697", label: "label-758")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
