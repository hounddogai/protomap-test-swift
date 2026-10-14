@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemorySeasonalReadGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.SeasonalReadGroupStore = Imaging.newMemorySeasonalReadGroupStore()
        let item = Imaging.newSeasonalReadGroup("code-147", label: "label-143")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
