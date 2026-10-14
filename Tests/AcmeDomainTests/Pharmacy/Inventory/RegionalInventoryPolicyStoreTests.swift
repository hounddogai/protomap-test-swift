@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRegionalInventoryPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RegionalInventoryPolicyStore = Pharmacy.newMemoryRegionalInventoryPolicyStore()
        let item = Pharmacy.newRegionalInventoryPolicy("code-732", title: "title-976")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
