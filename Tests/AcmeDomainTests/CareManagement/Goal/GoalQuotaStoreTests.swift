@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalQuotaStore = CareManagement.newMemoryGoalQuotaStore()
        let item = CareManagement.newGoalQuota("code-909", label: "label-584")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
