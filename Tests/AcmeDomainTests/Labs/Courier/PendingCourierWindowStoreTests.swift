@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPendingCourierWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PendingCourierWindowStore = Labs.newMemoryPendingCourierWindowStore()
        let item = Labs.newPendingCourierWindow("code-900", name: "name-253")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
