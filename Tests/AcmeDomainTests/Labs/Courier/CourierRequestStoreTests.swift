@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierRequestStore = Labs.newMemoryCourierRequestStore()
        let item = Labs.newCourierRequest("code-563", title: "title-809")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
