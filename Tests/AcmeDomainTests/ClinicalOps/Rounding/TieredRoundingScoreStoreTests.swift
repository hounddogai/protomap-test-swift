@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTieredRoundingScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TieredRoundingScoreStore = ClinicalOps.newMemoryTieredRoundingScoreStore()
        let item = ClinicalOps.newTieredRoundingScore("code-364", name: "name-778")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
