@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryStrictFormularyBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.StrictFormularyBaselineStore = Pharmacy.newMemoryStrictFormularyBaselineStore()
        let item = Pharmacy.newStrictFormularyBaseline("code-105", title: "title-471")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
