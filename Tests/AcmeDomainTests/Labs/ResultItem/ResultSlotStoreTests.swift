@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultSlotStore = Labs.newMemoryResultSlotStore()
        let item = Labs.newResultSlot("code-959", label: "label-858")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
