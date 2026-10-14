@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalPreferenceStore = CareManagement.newMemoryGoalPreferenceStore()
        let item = CareManagement.newGoalPreference("code-711", title: "title-756")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
