@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPendingModalityNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PendingModalityNoticeStore = Imaging.newMemoryPendingModalityNoticeStore()
        let item = Imaging.newPendingModalityNotice("code-502", title: "title-298")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
