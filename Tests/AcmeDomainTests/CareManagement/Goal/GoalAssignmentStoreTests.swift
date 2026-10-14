@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalAssignmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalAssignmentStore = CareManagement.newMemoryGoalAssignmentStore()
        let item = CareManagement.newGoalAssignment("code-455", title: "title-100")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
