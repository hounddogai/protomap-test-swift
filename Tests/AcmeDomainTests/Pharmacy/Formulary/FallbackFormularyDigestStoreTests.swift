@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFallbackFormularyDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FallbackFormularyDigestStore = Pharmacy.newMemoryFallbackFormularyDigestStore()
        let item = Pharmacy.newFallbackFormularyDigest("code-147", name: "name-426")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
