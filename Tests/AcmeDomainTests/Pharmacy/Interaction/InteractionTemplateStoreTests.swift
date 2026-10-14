@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionTemplateStore = Pharmacy.newMemoryInteractionTemplateStore()
        let item = Pharmacy.newInteractionTemplate("code-565", label: "label-20")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
