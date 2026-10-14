@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemorySeasonalRoundingScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.SeasonalRoundingScoreStore = ClinicalOps.newMemorySeasonalRoundingScoreStore()
        let item = ClinicalOps.newSeasonalRoundingScore("code-732", label: "label-821")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
