@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFormularyBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FormularyBaselineStore = Pharmacy.newMemoryFormularyBaselineStore()
        let item = Pharmacy.newFormularyBaseline("code-635", title: "title-346")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
