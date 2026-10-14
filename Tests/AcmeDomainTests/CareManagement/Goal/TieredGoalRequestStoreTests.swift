@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryTieredGoalRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.TieredGoalRequestStore = CareManagement.newMemoryTieredGoalRequestStore()
        let item = CareManagement.newTieredGoalRequest("code-70", title: "title-724")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
