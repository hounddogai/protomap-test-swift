@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryScheduledAccessionMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ScheduledAccessionMilestoneStore = Labs.newMemoryScheduledAccessionMilestoneStore()
        let item = Labs.newScheduledAccessionMilestone("code-527", label: "label-358")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
