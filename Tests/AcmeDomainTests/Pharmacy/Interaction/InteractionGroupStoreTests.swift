@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionGroupStore = Pharmacy.newMemoryInteractionGroupStore()
        let item = Pharmacy.newInteractionGroup("code-116", label: "label-988")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
