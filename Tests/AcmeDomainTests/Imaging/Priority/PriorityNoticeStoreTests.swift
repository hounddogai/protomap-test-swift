@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityNoticeStore = Imaging.newMemoryPriorityNoticeStore()
        let item = Imaging.newPriorityNotice("code-992", title: "title-486")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
