@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRegionalSubstitutionForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RegionalSubstitutionForecastStore = Pharmacy.newMemoryRegionalSubstitutionForecastStore()
        let item = Pharmacy.newRegionalSubstitutionForecast("code-147", name: "name-155")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
