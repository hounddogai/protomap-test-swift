@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadDraftStore = Imaging.newMemoryReadDraftStore()
        let item = Imaging.newReadDraft("code-355", label: "label-458")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
