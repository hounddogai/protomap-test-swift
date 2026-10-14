@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionMappingStore = Pharmacy.newMemoryInteractionMappingStore()
        let item = Pharmacy.newInteractionMapping("code-932", title: "title-610")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
