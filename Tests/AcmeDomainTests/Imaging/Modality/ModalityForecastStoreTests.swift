@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityForecastStore = Imaging.newMemoryModalityForecastStore()
        let item = Imaging.newModalityForecast("code-691", name: "name-682")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
