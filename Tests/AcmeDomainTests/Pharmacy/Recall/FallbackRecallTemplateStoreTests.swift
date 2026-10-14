@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFallbackRecallTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FallbackRecallTemplateStore = Pharmacy.newMemoryFallbackRecallTemplateStore()
        let item = Pharmacy.newFallbackRecallTemplate("code-152", name: "name-944")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
