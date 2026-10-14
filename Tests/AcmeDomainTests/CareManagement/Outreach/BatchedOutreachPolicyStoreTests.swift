@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryBatchedOutreachPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.BatchedOutreachPolicyStore = CareManagement.newMemoryBatchedOutreachPolicyStore()
        let item = CareManagement.newBatchedOutreachPolicy("code-298", name: "name-449")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
