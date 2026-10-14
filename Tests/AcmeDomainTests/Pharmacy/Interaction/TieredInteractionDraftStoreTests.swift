@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryTieredInteractionDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.TieredInteractionDraftStore = Pharmacy.newMemoryTieredInteractionDraftStore()
        let item = Pharmacy.newTieredInteractionDraft("code-883", title: "title-797")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
