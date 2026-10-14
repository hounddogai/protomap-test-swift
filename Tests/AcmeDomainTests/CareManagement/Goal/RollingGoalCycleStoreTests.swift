@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRollingGoalCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RollingGoalCycleStore = CareManagement.newMemoryRollingGoalCycleStore()
        let item = CareManagement.newRollingGoalCycle("code-329", title: "title-472")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
