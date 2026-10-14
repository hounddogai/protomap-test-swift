@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLegacyInteractionManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LegacyInteractionManifestStore = Pharmacy.newMemoryLegacyInteractionManifestStore()
        let item = Pharmacy.newLegacyInteractionManifest("code-839", label: "label-183")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
