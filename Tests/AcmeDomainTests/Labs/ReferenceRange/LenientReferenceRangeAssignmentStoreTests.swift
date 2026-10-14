@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLenientReferenceRangeAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LenientReferenceRangeAssignmentStore = Labs.newMemoryLenientReferenceRangeAssignmentStore()
        let item = Labs.newLenientReferenceRangeAssignment("code-341", label: "label-48")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
