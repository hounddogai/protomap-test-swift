@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDefaultFormularyOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DefaultFormularyOverrideStore = Pharmacy.newMemoryDefaultFormularyOverrideStore()
        let item = Pharmacy.newDefaultFormularyOverride("code-196", name: "name-891")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
