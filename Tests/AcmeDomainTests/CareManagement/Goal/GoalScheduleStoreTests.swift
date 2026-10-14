@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalScheduleStore = CareManagement.newMemoryGoalScheduleStore()
        let item = CareManagement.newGoalSchedule("code-338", name: "name-298")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
