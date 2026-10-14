@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryGlobalInventoryWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.GlobalInventoryWindowStore = Pharmacy.newMemoryGlobalInventoryWindowStore()
        let item = Pharmacy.newGlobalInventoryWindow("code-64", label: "label-764")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
