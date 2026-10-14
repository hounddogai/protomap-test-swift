@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryRegionalReadDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.RegionalReadDraftStore = Imaging.newMemoryRegionalReadDraftStore()
        let item = Imaging.newRegionalReadDraft("code-208", title: "title-557")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
