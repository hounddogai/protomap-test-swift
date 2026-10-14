@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPrimaryResultSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PrimaryResultSlotStore = Labs.newMemoryPrimaryResultSlotStore()
        let item = Labs.newPrimaryResultSlot("code-566", title: "title-262")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
