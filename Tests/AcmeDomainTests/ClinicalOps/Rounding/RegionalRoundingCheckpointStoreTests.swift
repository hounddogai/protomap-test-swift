@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRegionalRoundingCheckpointStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RegionalRoundingCheckpointStore = ClinicalOps.newMemoryRegionalRoundingCheckpointStore()
        let item = ClinicalOps.newRegionalRoundingCheckpoint("code-593", label: "label-475")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
