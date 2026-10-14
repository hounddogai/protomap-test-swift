@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionRecordStore = Pharmacy.newMemoryInteractionRecordStore()
        let item = Pharmacy.newInteractionRecord("code-950", name: "name-231")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
