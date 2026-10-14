@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryAdaptiveInteractionDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.AdaptiveInteractionDraftStore = Pharmacy.newMemoryAdaptiveInteractionDraftStore()
        let item = Pharmacy.newAdaptiveInteractionDraft("code-621", label: "label-64")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
