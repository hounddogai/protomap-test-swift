@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryGlobalResultSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.GlobalResultSlotStore = Labs.newMemoryGlobalResultSlotStore()
        let item = Labs.newGlobalResultSlot("code-823", name: "name-939")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
