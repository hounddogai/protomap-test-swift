@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryCappedDispenseCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.CappedDispenseCheckpointStore = Pharmacy.newMemoryCappedDispenseCheckpointStore()
        let item = Pharmacy.newCappedDispenseCheckpoint("code-568", title: "title-914")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
