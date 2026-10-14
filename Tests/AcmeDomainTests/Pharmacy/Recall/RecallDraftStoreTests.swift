@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallDraftStore = Pharmacy.newMemoryRecallDraftStore()
        let item = Pharmacy.newRecallDraft("code-68", title: "title-626")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
