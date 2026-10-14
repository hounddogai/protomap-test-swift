@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryDispenseForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.DispenseForecastStore = Pharmacy.newMemoryDispenseForecastStore()
        let item = Pharmacy.newDispenseForecast("code-229", name: "name-48")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
