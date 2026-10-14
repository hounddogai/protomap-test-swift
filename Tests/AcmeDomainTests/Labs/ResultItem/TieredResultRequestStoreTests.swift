@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryTieredResultRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.TieredResultRequestStore = Labs.newMemoryTieredResultRequestStore()
        let item = Labs.newTieredResultRequest("code-108", title: "title-588")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
