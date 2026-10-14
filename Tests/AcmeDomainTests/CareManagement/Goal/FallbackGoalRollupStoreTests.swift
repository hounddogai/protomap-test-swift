@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryFallbackGoalRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.FallbackGoalRollupStore = CareManagement.newMemoryFallbackGoalRollupStore()
        let item = CareManagement.newFallbackGoalRollup("code-892", name: "name-576")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
