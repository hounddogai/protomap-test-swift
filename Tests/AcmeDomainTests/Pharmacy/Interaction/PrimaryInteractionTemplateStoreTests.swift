@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPrimaryInteractionTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PrimaryInteractionTemplateStore = Pharmacy.newMemoryPrimaryInteractionTemplateStore()
        let item = Pharmacy.newPrimaryInteractionTemplate("code-216", label: "label-680")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
