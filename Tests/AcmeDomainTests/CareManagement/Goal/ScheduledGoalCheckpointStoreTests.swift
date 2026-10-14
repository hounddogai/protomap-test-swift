@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryScheduledGoalCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ScheduledGoalCheckpointStore = CareManagement.newMemoryScheduledGoalCheckpointStore()
        let item = CareManagement.newScheduledGoalCheckpoint("code-284", title: "title-359")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
