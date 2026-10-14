@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemorySeasonalRoundingCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.SeasonalRoundingCheckpointStore = ClinicalOps.newMemorySeasonalRoundingCheckpointStore()
        let item = ClinicalOps.newSeasonalRoundingCheckpoint("code-254", title: "title-456")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
