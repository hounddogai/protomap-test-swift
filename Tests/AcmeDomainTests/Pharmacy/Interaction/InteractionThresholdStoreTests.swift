@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionThresholdStore = Pharmacy.newMemoryInteractionThresholdStore()
        let item = Pharmacy.newInteractionThreshold("code-767", name: "name-876")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
