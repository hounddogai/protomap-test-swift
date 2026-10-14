@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryFallbackGoalClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.FallbackGoalClaimStore = CareManagement.newMemoryFallbackGoalClaimStore()
        let item = CareManagement.newFallbackGoalClaim("code-618", title: "title-78")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
