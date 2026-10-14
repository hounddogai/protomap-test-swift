@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityDraftStore = Imaging.newMemoryModalityDraftStore()
        let item = Imaging.newModalityDraft("code-655", name: "name-214")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
