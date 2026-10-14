@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryAdaptiveFormularyOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.AdaptiveFormularyOverrideStore = Pharmacy.newMemoryAdaptiveFormularyOverrideStore()
        let item = Pharmacy.newAdaptiveFormularyOverride("code-274", label: "label-825")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
