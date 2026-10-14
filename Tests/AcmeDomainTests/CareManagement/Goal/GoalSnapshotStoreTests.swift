@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalSnapshotStore = CareManagement.newMemoryGoalSnapshotStore()
        let item = CareManagement.newGoalSnapshot("code-401", label: "label-899")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
