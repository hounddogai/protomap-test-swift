@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierAllocationStore = Labs.newMemoryCourierAllocationStore()
        let item = Labs.newCourierAllocation("code-387", title: "title-496")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
