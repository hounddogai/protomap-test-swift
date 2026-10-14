@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPrimaryReadMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PrimaryReadMilestoneStore = Imaging.newMemoryPrimaryReadMilestoneStore()
        let item = Imaging.newPrimaryReadMilestone("code-526", title: "title-648")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
