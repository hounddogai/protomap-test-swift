@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolForecastStore = Imaging.newMemoryCareProtocolForecastStore()
        let item = Imaging.newCareProtocolForecast("code-388", name: "name-487")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
