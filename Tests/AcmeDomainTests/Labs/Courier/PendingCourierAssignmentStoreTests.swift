@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPendingCourierAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PendingCourierAssignmentStore = Labs.newMemoryPendingCourierAssignmentStore()
        let item = Labs.newPendingCourierAssignment("code-329", name: "name-263")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
