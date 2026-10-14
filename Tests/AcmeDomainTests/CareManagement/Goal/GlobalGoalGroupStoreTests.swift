@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGlobalGoalGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GlobalGoalGroupStore = CareManagement.newMemoryGlobalGoalGroupStore()
        let item = CareManagement.newGlobalGoalGroup("code-482", title: "title-926")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
