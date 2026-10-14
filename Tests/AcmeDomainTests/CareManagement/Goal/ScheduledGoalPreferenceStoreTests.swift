@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryScheduledGoalPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ScheduledGoalPreferenceStore = CareManagement.newMemoryScheduledGoalPreferenceStore()
        let item = CareManagement.newScheduledGoalPreference("code-17", name: "name-227")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
