@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFallbackDispenseManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FallbackDispenseManifestStore = Pharmacy.newMemoryFallbackDispenseManifestStore()
        let item = Pharmacy.newFallbackDispenseManifest("code-969", name: "name-876")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
