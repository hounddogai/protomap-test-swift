@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseRequestStore = Pharmacy.newMemoryDispenseRequestStore()
        let item = Pharmacy.newDispenseRequest("code-860", name: "name-622")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
