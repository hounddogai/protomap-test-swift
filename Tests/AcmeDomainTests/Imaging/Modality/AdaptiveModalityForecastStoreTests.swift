@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryAdaptiveModalityForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.AdaptiveModalityForecastStore = Imaging.newMemoryAdaptiveModalityForecastStore()
        let item = Imaging.newAdaptiveModalityForecast("code-939", label: "label-348")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
