@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPrimarySubstitutionManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PrimarySubstitutionManifestStore = Pharmacy.newMemoryPrimarySubstitutionManifestStore()
        let item = Pharmacy.newPrimarySubstitutionManifest("code-871", label: "label-572")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
