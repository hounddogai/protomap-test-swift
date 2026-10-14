@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierEntryStore = Labs.newMemoryCourierEntryStore()
        let item = Labs.newCourierEntry("code-371", title: "title-450")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
