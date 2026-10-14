@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFormularyOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FormularyOverrideStore = Pharmacy.newMemoryFormularyOverrideStore()
        let item = Pharmacy.newFormularyOverride("code-203", label: "label-53")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
