@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityForecastStore = Imaging.newMemoryPriorityForecastStore()
        let item = Imaging.newPriorityForecast("code-524", title: "title-882")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
