@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelAssignmentStore = Labs.newMemoryPanelAssignmentStore()
        let item = Labs.newPanelAssignment("code-314", title: "title-204")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
