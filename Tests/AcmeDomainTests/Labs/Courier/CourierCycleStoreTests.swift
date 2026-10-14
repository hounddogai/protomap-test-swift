@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierCycleStore = Labs.newMemoryCourierCycleStore()
        let item = Labs.newCourierCycle("code-406", name: "name-195")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
