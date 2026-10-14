@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolNoticeStore = Imaging.newMemoryCareProtocolNoticeStore()
        let item = Imaging.newCareProtocolNotice("code-576", title: "title-512")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
