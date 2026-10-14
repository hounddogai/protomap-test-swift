@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityNoticeStore = Imaging.newMemoryModalityNoticeStore()
        let item = Imaging.newModalityNotice("code-955", label: "label-698")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
