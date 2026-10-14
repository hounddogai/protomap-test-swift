@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPrimaryWorklistMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PrimaryWorklistMilestoneStore = Imaging.newMemoryPrimaryWorklistMilestoneStore()
        let item = Imaging.newPrimaryWorklistMilestone("code-376", label: "label-319")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
