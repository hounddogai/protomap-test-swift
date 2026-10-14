@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAdaptivePanelAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AdaptivePanelAllocationStore = Labs.newMemoryAdaptivePanelAllocationStore()
        let item = Labs.newAdaptivePanelAllocation("code-529", title: "title-608")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
