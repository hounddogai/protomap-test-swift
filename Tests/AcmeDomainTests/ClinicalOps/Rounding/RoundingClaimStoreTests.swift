@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingClaimStore = ClinicalOps.newMemoryRoundingClaimStore()
        let item = ClinicalOps.newRoundingClaim("code-540", name: "name-318")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
