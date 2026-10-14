@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryTieredWorklistEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.TieredWorklistEstimateStore = Imaging.newMemoryTieredWorklistEstimateStore()
        let item = Imaging.newTieredWorklistEstimate("code-152", title: "title-277")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
