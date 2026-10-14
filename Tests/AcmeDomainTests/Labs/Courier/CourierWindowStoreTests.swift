@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierWindowStore = Labs.newMemoryCourierWindowStore()
        let item = Labs.newCourierWindow("code-303", title: "title-349")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
