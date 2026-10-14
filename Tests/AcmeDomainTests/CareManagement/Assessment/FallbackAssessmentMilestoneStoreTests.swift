@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryFallbackAssessmentMilestoneStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.FallbackAssessmentMilestoneStore = CareManagement.newMemoryFallbackAssessmentMilestoneStore()
        let item = CareManagement.newFallbackAssessmentMilestone("code-366", name: "name-985")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
