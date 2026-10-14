@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGoalClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GoalClaimStore = CareManagement.newMemoryGoalClaimStore()
        let item = CareManagement.newGoalClaim("code-513", name: "name-184")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
