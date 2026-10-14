@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryLenientReadForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.LenientReadForecastStore = Imaging.newMemoryLenientReadForecastStore()
        let item = Imaging.newLenientReadForecast("code-582", label: "label-936")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
