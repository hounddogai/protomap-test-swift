@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierDraftStore = Labs.newMemoryCourierDraftStore()
        let item = Labs.newCourierDraft("code-118", name: "name-961")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
