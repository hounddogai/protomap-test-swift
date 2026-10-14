@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemorySeasonalPriorityMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.SeasonalPriorityMappingStore = Imaging.newMemorySeasonalPriorityMappingStore()
        let item = Imaging.newSeasonalPriorityMapping("code-344", name: "name-605")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
