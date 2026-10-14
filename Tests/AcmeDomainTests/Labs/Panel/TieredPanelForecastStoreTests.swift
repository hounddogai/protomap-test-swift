@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryTieredPanelForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.TieredPanelForecastStore = Labs.newMemoryTieredPanelForecastStore()
        let item = Labs.newTieredPanelForecast("code-741", title: "title-730")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
