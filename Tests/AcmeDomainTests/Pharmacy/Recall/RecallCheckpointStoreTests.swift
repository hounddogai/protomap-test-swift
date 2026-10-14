@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallCheckpointStore = Pharmacy.newMemoryRecallCheckpointStore()
        let item = Pharmacy.newRecallCheckpoint("code-164", title: "title-998")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
