@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryTieredResultPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.TieredResultPolicyStore = Labs.newMemoryTieredResultPolicyStore()
        let item = Labs.newTieredResultPolicy("code-156", title: "title-157")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
