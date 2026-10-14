@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryScheduledSpecimenDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ScheduledSpecimenDraftStore = Labs.newMemoryScheduledSpecimenDraftStore()
        let item = Labs.newScheduledSpecimenDraft("code-908", title: "title-2")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
