@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionCheckpointStore = Pharmacy.newMemoryInteractionCheckpointStore()
        let item = Pharmacy.newInteractionCheckpoint("code-161", name: "name-710")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
