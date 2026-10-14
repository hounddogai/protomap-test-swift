@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionAssignmentStore = Labs.newMemoryAccessionAssignmentStore()
        let item = Labs.newAccessionAssignment("code-286", label: "label-468")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
