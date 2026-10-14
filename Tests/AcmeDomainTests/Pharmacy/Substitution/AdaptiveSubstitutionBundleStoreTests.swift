@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryAdaptiveSubstitutionBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.AdaptiveSubstitutionBundleStore = Pharmacy.newMemoryAdaptiveSubstitutionBundleStore()
        let item = Pharmacy.newAdaptiveSubstitutionBundle("code-713", title: "title-130")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
