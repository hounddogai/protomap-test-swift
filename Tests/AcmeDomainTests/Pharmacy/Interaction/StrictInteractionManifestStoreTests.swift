@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryStrictInteractionManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.StrictInteractionManifestStore = Pharmacy.newMemoryStrictInteractionManifestStore()
        let item = Pharmacy.newStrictInteractionManifest("code-389", label: "label-690")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
