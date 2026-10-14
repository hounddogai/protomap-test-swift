@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCappedRiskScoreClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CappedRiskScoreClaimStore = CareManagement.newMemoryCappedRiskScoreClaimStore()
        let item = CareManagement.newCappedRiskScoreClaim("code-153", title: "title-93")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
