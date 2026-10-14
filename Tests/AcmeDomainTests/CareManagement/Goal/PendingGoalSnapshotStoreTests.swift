@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPendingGoalSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PendingGoalSnapshotStore = CareManagement.newMemoryPendingGoalSnapshotStore()
        let item = CareManagement.newPendingGoalSnapshot("code-428", name: "name-65")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
