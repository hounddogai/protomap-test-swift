@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLegacyResultForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LegacyResultForecastStore = Labs.newMemoryLegacyResultForecastStore()
        let item = Labs.newLegacyResultForecast("code-222", title: "title-245")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
