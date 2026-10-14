@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRollingResultPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RollingResultPolicyStore = Labs.newMemoryRollingResultPolicyStore()
        let item = Labs.newRollingResultPolicy("code-605", name: "name-679")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
