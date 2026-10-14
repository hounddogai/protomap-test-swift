@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDefaultRecallForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DefaultRecallForecastStore = Pharmacy.newMemoryDefaultRecallForecastStore()
        let item = Pharmacy.newDefaultRecallForecast("code-766", title: "title-636")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
