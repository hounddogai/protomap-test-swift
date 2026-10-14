@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionForecastStore = Labs.newMemoryAccessionForecastStore()
        let item = Labs.newAccessionForecast("code-663", title: "title-919")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
