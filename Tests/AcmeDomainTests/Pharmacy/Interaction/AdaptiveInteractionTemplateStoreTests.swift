@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryAdaptiveInteractionTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.AdaptiveInteractionTemplateStore = Pharmacy.newMemoryAdaptiveInteractionTemplateStore()
        let item = Pharmacy.newAdaptiveInteractionTemplate("code-549", label: "label-279")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
