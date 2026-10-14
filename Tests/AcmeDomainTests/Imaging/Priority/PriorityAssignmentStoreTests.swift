@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityAssignmentStore = Imaging.newMemoryPriorityAssignmentStore()
        let item = Imaging.newPriorityAssignment("code-894", label: "label-663")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
