@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLenientInventoryDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LenientInventoryDigestStore = Pharmacy.newMemoryLenientInventoryDigestStore()
        let item = Pharmacy.newLenientInventoryDigest("code-369", label: "label-490")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
