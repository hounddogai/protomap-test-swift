@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryScheduledGoalPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ScheduledGoalPolicyStore = CareManagement.newMemoryScheduledGoalPolicyStore()
        let item = CareManagement.newScheduledGoalPolicy("code-255", title: "title-533")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
