@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryLenientStudyDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.LenientStudyDraftStore = Imaging.newMemoryLenientStudyDraftStore()
        let item = Imaging.newLenientStudyDraft("code-961", title: "title-313")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
