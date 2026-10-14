@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryScheduledPriorityEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ScheduledPriorityEstimateStore = Imaging.newMemoryScheduledPriorityEstimateStore()
        let item = Imaging.newScheduledPriorityEstimate("code-19", title: "title-625")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
