@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryFallbackCourierDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.FallbackCourierDraftStore = Labs.newMemoryFallbackCourierDraftStore()
        let item = Labs.newFallbackCourierDraft("code-625", label: "label-839")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
