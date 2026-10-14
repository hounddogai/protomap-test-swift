@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryLegacyRecallTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.LegacyRecallTemplateStore = Pharmacy.newMemoryLegacyRecallTemplateStore()
        let item = Pharmacy.newLegacyRecallTemplate("code-696", title: "title-385")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
