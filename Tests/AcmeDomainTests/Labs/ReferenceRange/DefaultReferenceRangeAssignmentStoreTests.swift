@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryDefaultReferenceRangeAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.DefaultReferenceRangeAssignmentStore = Labs.newMemoryDefaultReferenceRangeAssignmentStore()
        let item = Labs.newDefaultReferenceRangeAssignment("code-691", name: "name-83")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
