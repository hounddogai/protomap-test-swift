@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryAdaptivePriorityMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.AdaptivePriorityMilestoneStore = Imaging.newMemoryAdaptivePriorityMilestoneStore()
        let item = Imaging.newAdaptivePriorityMilestone("code-169", name: "name-15")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
