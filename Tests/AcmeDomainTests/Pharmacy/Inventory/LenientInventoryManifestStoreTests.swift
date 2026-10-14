@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLenientInventoryManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LenientInventoryManifestStore = Pharmacy.newMemoryLenientInventoryManifestStore()
        let item = Pharmacy.newLenientInventoryManifest("code-323", title: "title-943")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
