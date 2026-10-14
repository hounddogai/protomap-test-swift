@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryLegacyAssessmentMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.LegacyAssessmentMilestoneStore = CareManagement.newMemoryLegacyAssessmentMilestoneStore()
        let item = CareManagement.newLegacyAssessmentMilestone("code-329", name: "name-855")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
