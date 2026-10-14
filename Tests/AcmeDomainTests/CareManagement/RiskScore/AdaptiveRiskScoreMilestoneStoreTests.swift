@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryAdaptiveRiskScoreMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.AdaptiveRiskScoreMilestoneStore = CareManagement.newMemoryAdaptiveRiskScoreMilestoneStore()
        let item = CareManagement.newAdaptiveRiskScoreMilestone("code-361", title: "title-890")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
