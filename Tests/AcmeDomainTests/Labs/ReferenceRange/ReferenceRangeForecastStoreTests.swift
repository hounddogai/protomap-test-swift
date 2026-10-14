@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeForecastStore = Labs.newMemoryReferenceRangeForecastStore()
        let item = Labs.newReferenceRangeForecast("code-891", title: "title-503")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
