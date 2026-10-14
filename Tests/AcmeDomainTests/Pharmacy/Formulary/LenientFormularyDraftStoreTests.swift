@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLenientFormularyDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LenientFormularyDraftStore = Pharmacy.newMemoryLenientFormularyDraftStore()
        let item = Pharmacy.newLenientFormularyDraft("code-149", name: "name-692")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
