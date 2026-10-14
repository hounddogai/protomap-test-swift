@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemorySeasonalReadMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.SeasonalReadMilestoneStore = Imaging.newMemorySeasonalReadMilestoneStore()
        let item = Imaging.newSeasonalReadMilestone("code-966", name: "name-637")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
