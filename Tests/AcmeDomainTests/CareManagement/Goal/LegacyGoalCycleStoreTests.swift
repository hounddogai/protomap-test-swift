@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLegacyGoalCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LegacyGoalCycleStore = CareManagement.newMemoryLegacyGoalCycleStore()
        let item = CareManagement.newLegacyGoalCycle("code-738", title: "title-456")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
