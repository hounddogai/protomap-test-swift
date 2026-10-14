@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryTieredRiskScoreClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.TieredRiskScoreClaimStore = CareManagement.newMemoryTieredRiskScoreClaimStore()
        let item = CareManagement.newTieredRiskScoreClaim("code-870", name: "name-462")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
