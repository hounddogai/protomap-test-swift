@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionDraftStore = Labs.newMemoryAccessionDraftStore()
        let item = Labs.newAccessionDraft("code-28", name: "name-487")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
