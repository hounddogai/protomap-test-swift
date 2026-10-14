@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDefaultDispenseManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DefaultDispenseManifestStore = Pharmacy.newMemoryDefaultDispenseManifestStore()
        let item = Pharmacy.newDefaultDispenseManifest("code-815", title: "title-860")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
