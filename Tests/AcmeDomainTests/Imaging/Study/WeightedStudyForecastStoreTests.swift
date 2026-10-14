@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWeightedStudyForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WeightedStudyForecastStore = Imaging.newMemoryWeightedStudyForecastStore()
        let item = Imaging.newWeightedStudyForecast("code-706", name: "name-281")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
