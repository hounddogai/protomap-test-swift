@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistLedgerStore = Imaging.newMemoryWorklistLedgerStore()
        let item = Imaging.newWorklistLedger("code-939", name: "name-12")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
