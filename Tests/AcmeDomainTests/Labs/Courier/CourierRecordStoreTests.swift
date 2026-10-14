@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierRecordStore = Labs.newMemoryCourierRecordStore()
        let item = Labs.newCourierRecord("code-524", name: "name-848")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
