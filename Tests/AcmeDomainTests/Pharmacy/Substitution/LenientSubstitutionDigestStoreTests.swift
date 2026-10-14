@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLenientSubstitutionDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LenientSubstitutionDigestStore = Pharmacy.newMemoryLenientSubstitutionDigestStore()
        let item = Pharmacy.newLenientSubstitutionDigest("code-412", title: "title-460")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
