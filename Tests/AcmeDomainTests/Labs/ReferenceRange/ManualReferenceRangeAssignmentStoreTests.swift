@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryManualReferenceRangeAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ManualReferenceRangeAssignmentStore = Labs.newMemoryManualReferenceRangeAssignmentStore()
        let item = Labs.newManualReferenceRangeAssignment("code-646", name: "name-779")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
