@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenDraftStore = Labs.newMemorySpecimenDraftStore()
        let item = Labs.newSpecimenDraft("code-253", name: "name-32")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
