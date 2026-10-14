@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryFallbackGoalGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.FallbackGoalGroupStore = CareManagement.newMemoryFallbackGoalGroupStore()
        let item = CareManagement.newFallbackGoalGroup("code-336", title: "title-753")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
