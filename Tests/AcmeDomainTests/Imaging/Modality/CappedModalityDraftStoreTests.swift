@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCappedModalityDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CappedModalityDraftStore = Imaging.newMemoryCappedModalityDraftStore()
        let item = Imaging.newCappedModalityDraft("code-299", label: "label-197")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
