@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInteractionForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InteractionForecastStore = Pharmacy.newMemoryInteractionForecastStore()
        let item = Pharmacy.newInteractionForecast("code-659", title: "title-893")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
