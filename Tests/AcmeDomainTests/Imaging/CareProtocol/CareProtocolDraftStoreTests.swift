@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolDraftStore = Imaging.newMemoryCareProtocolDraftStore()
        let item = Imaging.newCareProtocolDraft("code-885", name: "name-754")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
