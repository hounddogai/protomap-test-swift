@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryAdaptiveStudyLedgerStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.AdaptiveStudyLedgerStore = Imaging.newMemoryAdaptiveStudyLedgerStore()
        let item = Imaging.newAdaptiveStudyLedger("code-803", name: "name-938")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
