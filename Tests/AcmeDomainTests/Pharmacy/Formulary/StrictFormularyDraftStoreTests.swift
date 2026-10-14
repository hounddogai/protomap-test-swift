@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryStrictFormularyDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.StrictFormularyDraftStore = Pharmacy.newMemoryStrictFormularyDraftStore()
        let item = Pharmacy.newStrictFormularyDraft("code-636", title: "title-370")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
