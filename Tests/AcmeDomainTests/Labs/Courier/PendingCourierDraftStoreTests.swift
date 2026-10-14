@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPendingCourierDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PendingCourierDraftStore = Labs.newMemoryPendingCourierDraftStore()
        let item = Labs.newPendingCourierDraft("code-631", title: "title-365")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
