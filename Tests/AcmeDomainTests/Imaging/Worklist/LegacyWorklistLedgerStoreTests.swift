@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryLegacyWorklistLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.LegacyWorklistLedgerStore = Imaging.newMemoryLegacyWorklistLedgerStore()
        let item = Imaging.newLegacyWorklistLedger("code-636", label: "label-553")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
