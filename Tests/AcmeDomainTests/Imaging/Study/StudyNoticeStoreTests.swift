@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyNoticeStore = Imaging.newMemoryStudyNoticeStore()
        let item = Imaging.newStudyNotice("code-31", name: "name-547")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
