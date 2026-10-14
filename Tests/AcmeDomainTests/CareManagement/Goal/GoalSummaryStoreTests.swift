@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalSummaryStore = CareManagement.newMemoryGoalSummaryStore()
        let item = CareManagement.newGoalSummary("code-648", title: "title-699")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
