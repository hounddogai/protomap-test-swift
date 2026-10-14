@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryStrictGoalGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.StrictGoalGroupStore = CareManagement.newMemoryStrictGoalGroupStore()
        let item = CareManagement.newStrictGoalGroup("code-750", name: "name-44")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
