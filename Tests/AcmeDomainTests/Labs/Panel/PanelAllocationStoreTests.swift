@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPanelAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PanelAllocationStore = Labs.newMemoryPanelAllocationStore()
        let item = Labs.newPanelAllocation("code-627", title: "title-722")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
