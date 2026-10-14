@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLegacyCourierWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LegacyCourierWindowStore = Labs.newMemoryLegacyCourierWindowStore()
        let item = Labs.newLegacyCourierWindow("code-347", title: "title-751")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
