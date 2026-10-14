@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallForecastStore = Pharmacy.newMemoryRecallForecastStore()
        let item = Pharmacy.newRecallForecast("code-715", title: "title-804")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
