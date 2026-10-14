@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryAdaptiveReadLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.AdaptiveReadLedgerStore = Imaging.newMemoryAdaptiveReadLedgerStore()
        let item = Imaging.newAdaptiveReadLedger("code-950", label: "label-124")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
