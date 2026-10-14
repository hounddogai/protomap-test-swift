@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryAdaptiveFormularyDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.AdaptiveFormularyDigestStore = Pharmacy.newMemoryAdaptiveFormularyDigestStore()
        let item = Pharmacy.newAdaptiveFormularyDigest("code-596", label: "label-839")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
