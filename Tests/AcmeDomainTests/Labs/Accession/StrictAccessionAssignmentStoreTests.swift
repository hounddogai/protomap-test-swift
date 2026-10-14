@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryStrictAccessionAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.StrictAccessionAssignmentStore = Labs.newMemoryStrictAccessionAssignmentStore()
        let item = Labs.newStrictAccessionAssignment("code-822", title: "title-934")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
