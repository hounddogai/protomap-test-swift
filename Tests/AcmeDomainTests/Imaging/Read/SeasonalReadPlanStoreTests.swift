@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemorySeasonalReadPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.SeasonalReadPlanStore = Imaging.newMemorySeasonalReadPlanStore()
        let item = Imaging.newSeasonalReadPlan("code-396", name: "name-111")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
