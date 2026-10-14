@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemorySeasonalHandoffMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.SeasonalHandoffMilestoneStore = ClinicalOps.newMemorySeasonalHandoffMilestoneStore()
        let item = ClinicalOps.newSeasonalHandoffMilestone("code-208", label: "label-666")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
