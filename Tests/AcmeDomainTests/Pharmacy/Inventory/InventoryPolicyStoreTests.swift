@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventoryPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventoryPolicyStore = Pharmacy.newMemoryInventoryPolicyStore()
        let item = Pharmacy.newInventoryPolicy("code-70", name: "name-626")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
