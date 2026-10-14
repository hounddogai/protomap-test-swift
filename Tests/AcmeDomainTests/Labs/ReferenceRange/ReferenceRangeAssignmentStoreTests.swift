@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeAssignmentStore = Labs.newMemoryReferenceRangeAssignmentStore()
        let item = Labs.newReferenceRangeAssignment("code-480", name: "name-78")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
