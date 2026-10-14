@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventoryDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventoryDigestStore = Pharmacy.newMemoryInventoryDigestStore()
        let item = Pharmacy.newInventoryDigest("code-871", title: "title-316")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
