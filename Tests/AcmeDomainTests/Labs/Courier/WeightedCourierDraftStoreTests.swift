@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryWeightedCourierDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.WeightedCourierDraftStore = Labs.newMemoryWeightedCourierDraftStore()
        let item = Labs.newWeightedCourierDraft("code-39", title: "title-842")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
