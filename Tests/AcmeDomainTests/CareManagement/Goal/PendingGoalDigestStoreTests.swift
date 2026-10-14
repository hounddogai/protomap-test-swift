@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPendingGoalDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PendingGoalDigestStore = CareManagement.newMemoryPendingGoalDigestStore()
        let item = CareManagement.newPendingGoalDigest("code-197", title: "title-320")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
