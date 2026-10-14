@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryGlobalInteractionTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.GlobalInteractionTemplateStore = Pharmacy.newMemoryGlobalInteractionTemplateStore()
        let item = Pharmacy.newGlobalInteractionTemplate("code-301", title: "title-880")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
