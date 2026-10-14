@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryStrictPanelAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.StrictPanelAssignmentStore = Labs.newMemoryStrictPanelAssignmentStore()
        let item = Labs.newStrictPanelAssignment("code-231", title: "title-94")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
