@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityDraftStore = Imaging.newMemoryPriorityDraftStore()
        let item = Imaging.newPriorityDraft("code-680", title: "title-604")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
