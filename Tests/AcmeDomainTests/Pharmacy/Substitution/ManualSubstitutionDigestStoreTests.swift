@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryManualSubstitutionDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.ManualSubstitutionDigestStore = Pharmacy.newMemoryManualSubstitutionDigestStore()
        let item = Pharmacy.newManualSubstitutionDigest("code-835", name: "name-699")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
