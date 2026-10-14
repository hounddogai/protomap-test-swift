@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryStrictTaskMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.StrictTaskMilestoneStore = ClinicalOps.newMemoryStrictTaskMilestoneStore()
        let item = ClinicalOps.newStrictTaskMilestone("code-424", title: "title-628")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
