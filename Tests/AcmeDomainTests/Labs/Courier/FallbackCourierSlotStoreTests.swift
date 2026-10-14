@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryFallbackCourierSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.FallbackCourierSlotStore = Labs.newMemoryFallbackCourierSlotStore()
        let item = Labs.newFallbackCourierSlot("code-121", name: "name-266")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
