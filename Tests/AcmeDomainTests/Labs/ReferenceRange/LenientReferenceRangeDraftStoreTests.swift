@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLenientReferenceRangeDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LenientReferenceRangeDraftStore = Labs.newMemoryLenientReferenceRangeDraftStore()
        let item = Labs.newLenientReferenceRangeDraft("code-250", title: "title-55")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
