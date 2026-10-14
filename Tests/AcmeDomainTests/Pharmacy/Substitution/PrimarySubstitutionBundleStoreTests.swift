@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPrimarySubstitutionBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PrimarySubstitutionBundleStore = Pharmacy.newMemoryPrimarySubstitutionBundleStore()
        let item = Pharmacy.newPrimarySubstitutionBundle("code-255", name: "name-95")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
