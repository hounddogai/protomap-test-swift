@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionPreferenceStore = Pharmacy.newMemoryInteractionPreferenceStore()
        let item = Pharmacy.newInteractionPreference("code-671", label: "label-168")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
