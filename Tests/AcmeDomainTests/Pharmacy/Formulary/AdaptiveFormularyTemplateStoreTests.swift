@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryAdaptiveFormularyTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.AdaptiveFormularyTemplateStore = Pharmacy.newMemoryAdaptiveFormularyTemplateStore()
        let item = Pharmacy.newAdaptiveFormularyTemplate("code-608", label: "label-716")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
