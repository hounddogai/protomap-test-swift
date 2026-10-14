@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryRegionalStudyDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.RegionalStudyDraftStore = Imaging.newMemoryRegionalStudyDraftStore()
        let item = Imaging.newRegionalStudyDraft("code-383", title: "title-352")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
