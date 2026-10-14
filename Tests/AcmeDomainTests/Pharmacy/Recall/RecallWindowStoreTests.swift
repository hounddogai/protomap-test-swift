@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallWindowStore = Pharmacy.newMemoryRecallWindowStore()
        let item = Pharmacy.newRecallWindow("code-442", title: "title-750")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
