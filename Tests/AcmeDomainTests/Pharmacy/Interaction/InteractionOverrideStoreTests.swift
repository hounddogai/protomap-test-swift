@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionOverrideStore = Pharmacy.newMemoryInteractionOverrideStore()
        let item = Pharmacy.newInteractionOverride("code-539", title: "title-264")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
