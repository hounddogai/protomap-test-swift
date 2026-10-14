@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingMilestoneStore = ClinicalOps.newMemoryRoundingMilestoneStore()
        let item = ClinicalOps.newRoundingMilestone("code-584", name: "name-162")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
