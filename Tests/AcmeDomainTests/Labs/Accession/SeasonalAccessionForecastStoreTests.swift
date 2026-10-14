@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySeasonalAccessionForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SeasonalAccessionForecastStore = Labs.newMemorySeasonalAccessionForecastStore()
        let item = Labs.newSeasonalAccessionForecast("code-12", label: "label-766")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
