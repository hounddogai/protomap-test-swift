@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionBatchStore = Pharmacy.newMemoryInteractionBatchStore()
        let item = Pharmacy.newInteractionBatch("code-615", name: "name-662")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
