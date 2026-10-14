@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPrimaryResultPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PrimaryResultPolicyStore = Labs.newMemoryPrimaryResultPolicyStore()
        let item = Labs.newPrimaryResultPolicy("code-997", title: "title-232")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
