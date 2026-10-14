@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPrimaryModalityDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PrimaryModalityDraftStore = Imaging.newMemoryPrimaryModalityDraftStore()
        let item = Imaging.newPrimaryModalityDraft("code-408", label: "label-38")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
