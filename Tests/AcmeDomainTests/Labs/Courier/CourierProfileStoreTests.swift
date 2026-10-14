@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierProfileStore = Labs.newMemoryCourierProfileStore()
        let item = Labs.newCourierProfile("code-173", title: "title-62")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
