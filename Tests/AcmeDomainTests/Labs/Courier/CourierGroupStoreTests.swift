@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierGroupStore = Labs.newMemoryCourierGroupStore()
        let item = Labs.newCourierGroup("code-172", title: "title-214")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
