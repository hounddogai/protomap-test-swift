@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryGlobalStudyNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.GlobalStudyNoticeStore = Imaging.newMemoryGlobalStudyNoticeStore()
        let item = Imaging.newGlobalStudyNotice("code-301", name: "name-118")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
