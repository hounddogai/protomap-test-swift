@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryManualInventoryManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.ManualInventoryManifestStore = Pharmacy.newMemoryManualInventoryManifestStore()
        let item = Pharmacy.newManualInventoryManifest("code-99", label: "label-824")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
