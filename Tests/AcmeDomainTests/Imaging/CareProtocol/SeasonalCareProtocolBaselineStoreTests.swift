@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemorySeasonalCareProtocolBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.SeasonalCareProtocolBaselineStore = Imaging.newMemorySeasonalCareProtocolBaselineStore()
        let item = Imaging.newSeasonalCareProtocolBaseline("code-924", name: "name-329")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
