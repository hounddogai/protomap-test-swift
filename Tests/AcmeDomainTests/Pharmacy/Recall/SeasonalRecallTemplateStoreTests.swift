@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemorySeasonalRecallTemplateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.SeasonalRecallTemplateStore = Pharmacy.newMemorySeasonalRecallTemplateStore()
        let item = Pharmacy.newSeasonalRecallTemplate("code-195", title: "title-295")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
