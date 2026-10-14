@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFallbackDispenseRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FallbackDispenseRequestStore = Pharmacy.newMemoryFallbackDispenseRequestStore()
        let item = Pharmacy.newFallbackDispenseRequest("code-767", title: "title-979")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
