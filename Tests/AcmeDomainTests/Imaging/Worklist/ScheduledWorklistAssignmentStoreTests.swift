@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryScheduledWorklistAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ScheduledWorklistAssignmentStore = Imaging.newMemoryScheduledWorklistAssignmentStore()
        let item = Imaging.newScheduledWorklistAssignment("code-280", name: "name-556")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
