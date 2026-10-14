@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierSlotStore = Labs.newMemoryCourierSlotStore()
        let item = Labs.newCourierSlot("code-678", name: "name-232")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
