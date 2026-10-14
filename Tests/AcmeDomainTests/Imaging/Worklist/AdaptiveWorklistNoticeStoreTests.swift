@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryAdaptiveWorklistNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.AdaptiveWorklistNoticeStore = Imaging.newMemoryAdaptiveWorklistNoticeStore()
        let item = Imaging.newAdaptiveWorklistNotice("code-526", title: "title-912")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
